import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function normalizePhone(phone: string): string {
  if (!phone) return "";
  const digits = phone.replace(/\D/g, "");
  return digits.length > 10 ? digits.slice(-10) : digits;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "https://kxeqayzxfvoedqvilcmp.supabase.co";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const body = await req.json().catch(() => ({}));
    const username = body.username;
    const phone = body.phone;

    if (!username || !phone) {
      return new Response(
        JSON.stringify({ error: "اسم المستخدم أو رقم الهاتف غير صحيح" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const cleanUsername = String(username).trim();
    const cleanPhone = String(phone).trim();

    // 1. Search in public.users by username only (UNIQUE constraint)
    const { data: user, error: fetchErr } = await supabase
      .from("users")
      .select("id, username, email, phone, role, failed_login_attempts, locked_until")
      .ilike("username", cleanUsername)
      .maybeSingle();

    if (fetchErr || !user) {
      return new Response(
        JSON.stringify({ error: "اسم المستخدم أو رقم الهاتف غير صحيح" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Rate Limiting Check (Lockout Status)
    if (user.locked_until) {
      const lockTime = new Date(user.locked_until).getTime();
      const nowTime = new Date().getTime();
      if (lockTime > nowTime) {
        return new Response(
          JSON.stringify({ error: "تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة" }),
          { status: 423, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 3. Normalize & Compare Phone Numbers
    const storedPhoneNorm = normalizePhone(user.phone ?? "");
    const inputPhoneNorm = normalizePhone(cleanPhone);

    const isMatch = (storedPhoneNorm !== "" && storedPhoneNorm === inputPhoneNorm) ||
                    (storedPhoneNorm === "" && inputPhoneNorm !== "");

    if (!isMatch) {
      const currentFailed = (user.failed_login_attempts || 0) + 1;
      let updatePayload: Record<string, any> = { failed_login_attempts: currentFailed };

      if (currentFailed >= 5) {
        const lockUntil = new Date(Date.now() + 15 * 60 * 1000).toISOString();
        updatePayload.locked_until = lockUntil;
      }

      await supabase.from("users").update(updatePayload).eq("id", user.id);

      if (currentFailed >= 5) {
        return new Response(
          JSON.stringify({ error: "تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة" }),
          { status: 423, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ error: "اسم المستخدم أو رقم الهاتف غير صحيح" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update phone if empty in database
    if (!user.phone && inputPhoneNorm) {
      await supabase.from("users").update({ phone: cleanPhone }).eq("id", user.id);
    }

    // Reset failed login attempts & lockout on success
    await supabase.from("users").update({ failed_login_attempts: 0, locked_until: null }).eq("id", user.id);

    // 4. Generate Authentic Supabase Auth Session
    const userEmail = user.email || `${cleanUsername.toLowerCase()}@gmail.com`;

    let { data: authUserData, error: authUserErr } = await supabase.auth.admin.getUserByEmail(userEmail);

    if (authUserErr || !authUserData?.user) {
      const { data: newUser, error: createErr } = await supabase.auth.admin.createUser({
        email: userEmail,
        email_confirm: true,
        user_metadata: { username: cleanUsername },
      });
      if (createErr || !newUser.user) {
        throw new Error(`Failed creating auth user: ${createErr?.message}`);
      }
      authUserData = { user: newUser.user };
    }

    const { data: linkData, error: linkErr } = await supabase.auth.admin.generateLink({
      type: "magiclink",
      email: userEmail,
    });

    if (linkErr || !linkData?.properties) {
      throw new Error(`Failed generating session link: ${linkErr?.message}`);
    }

    return new Response(
      JSON.stringify({
        message: "تم تسجيل الدخول بنجاح",
        email_otp: linkData.properties.email_otp,
        email: userEmail,
        user: {
          id: user.id,
          username: user.username,
          email: userEmail,
          phone: user.phone || cleanPhone,
          role: user.role || "customer",
          is_admin: user.role === "admin" || user.role === "owner",
          is_employee: user.role === "employee",
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "حدث خطأ غير متوقع أثناء تسجيل الدخول" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
