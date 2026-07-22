const BASE_URL = '/api';

async function checkAuth() {
    try {
        const res = await fetch(BASE_URL + '/me');
        if (res.ok) {
            const user = await res.json();
            showDashboard(user);
        } else {
            showLogin();
        }
    } catch (error) {
        console.error('Auth check failed:', error);
        showLogin();
    }
}

function showLogin() {
    document.getElementById('authPage').classList.remove('hidden');
    document.getElementById('dashboardPage').classList.add('hidden');
}

function showDashboard(user) {
    document.getElementById('authPage').classList.add('hidden');
    document.getElementById('dashboardPage').classList.remove('hidden');
    document.getElementById('currentUsername').textContent = user.username;
    document.getElementById('currentUserRole').textContent = user.role === 'admin' ? 'مسؤول النظام' : 'موظف';
    window.CURRENT_USER_ID = user.id;

    if (user.role === 'admin') {
        loadAdminDashboard();
    } else {
        loadEmployeeDashboard();
    }
}

async function logout() {
    await fetch(BASE_URL + '/logout', { method: 'POST' });
    showLogin();
    document.getElementById('loginForm').reset();
}

function handleQuickAction(value) {
    if (!value) return;
    const el = document.getElementById(value);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    document.getElementById('quickActionsSelect').value = '';
}

document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const remember = document.getElementById('rememberMe').checked;
    const errorDiv = document.getElementById('loginError');

    try {
        const res = await fetch(BASE_URL + '/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password, remember })
        });

        if (res.ok) {
            if (remember) {
                localStorage.setItem('bolaRememberedUsername', username);
                localStorage.setItem('bolaRememberMe', 'true');
            } else {
                localStorage.removeItem('bolaRememberedUsername');
                localStorage.removeItem('bolaRememberMe');
            }
            const data = await res.json();
            showDashboard(data.user);
        } else {
            const data = await res.json();
            errorDiv.classList.remove('hidden');
            errorDiv.className = 'login-error';
            errorDiv.textContent = data.error || 'خطأ في تسجيل الدخول';
        }
    } catch (error) {
        errorDiv.classList.remove('hidden');
        errorDiv.className = 'login-error';
        errorDiv.textContent = 'خطأ: ' + error.message;
    }
});

function loadSavedLogin() {
    const savedUsername = localStorage.getItem('bolaRememberedUsername');
    const savedRemember = localStorage.getItem('bolaRememberMe') === 'true';
    if (savedUsername) {
        document.getElementById('username').value = savedUsername;
    }
    document.getElementById('rememberMe').checked = savedRemember;
}

async function loadAdminDashboard() {
    const grid = document.getElementById('mainGrid');
    grid.innerHTML = `
        <div class="card" style="grid-column: 1 / -1; border:2px solid #667eea; background:#f8f9ff;">
            <div style="font-size:1.2em; font-weight:700; color:#333; margin-bottom:10px;">لوحة العمليات السريعة</div>
            <div style="color:#666; margin-bottom:12px;">استخدم هذه القائمة للانتقال مباشرة إلى إضافة موظف أو تسجيل الحضور والغياب أو إدارة المهام.</div>
        </div>
        <div class="card" id="createUserCard">
            <div class="card-header">
                <div class="card-icon"><i class="fas fa-user-plus"></i></div>
                <div>
                    <div class="card-title">إضافة موظف جديد</div>
                    <div class="card-subtitle">أنشئ حسابات للموظفين الجدد</div>
                </div>
            </div>
            <form id="createUserForm">
                <div id="createUserMsg"></div>
                <div class="form-group"><label>اسم المستخدم</label><input type="text" id="newUsername" placeholder="مثال: أحمد محمد" required></div>
                <div class="form-group"><label>كلمة السر</label><input type="password" id="newPassword" placeholder="أدخل كلمة سر قوية" required></div>
                <button type="submit" class="btn-primary">+ إنشاء موظف</button>
            </form>
            <div style="margin-top:20px;">
                <form id="uploadFileForm" enctype="multipart/form-data">
                    <div id="uploadFileMsg"></div>
                    <div class="form-group"><label>رفع ملف لموظف</label><select id="uploadToUser"></select></div>
                    <div class="form-group"><input type="file" id="uploadFileInput" required></div>
                    <button type="submit" class="btn-primary">رفع الملف</button>
                </form>
            </div>
            <div class="list-section">
                <div class="list-title">قائمة الموظفين</div>
                <div class="items-container" id="usersList"></div>
            </div>
        </div>
        <div class="card" id="attendanceCard">
            <div class="card-header">
                <div class="card-icon"><i class="fas fa-calendar-check"></i></div>
                <div>
                    <div class="card-title">تسجيل الحضور والغياب</div>
                    <div class="card-subtitle">سجل حضور أو غياب أي موظف في يوم معين</div>
                </div>
            </div>
            <form id="attendanceForm">
                <div id="attendanceMsg"></div>
                <div class="form-group"><label>الموظف</label><select id="attendanceUser" required></select></div>
                <div class="form-group"><label>التاريخ</label><input type="date" id="attendanceDate" required></div>
                <div class="form-group"><label>الحالة</label><select id="attendanceStatus" required><option value="present">حضور</option><option value="absent">غياب</option></select></div>
                <button type="submit" class="btn-primary">حفظ الحالة</button>
            </form>
        </div>
        <div class="card" id="tasksCard">
            <div class="card-header">
                <div class="card-icon"><i class="fas fa-tasks"></i></div>
                <div>
                    <div class="card-title">إضافة مهمة</div>
                    <div class="card-subtitle">أسند مهام للموظفين</div>
                </div>
            </div>
            <form id="addTaskForm">
                <div id="addTaskMsg"></div>
                <div class="form-group"><label>عنوان المهمة</label><input type="text" id="taskTitle" placeholder="مثال: تطوير الميزة الجديدة" required></div>
                <div class="form-group"><label>الوصف</label><textarea id="taskDesc" placeholder="اشرح تفاصيل المهمة..."></textarea></div>
                <div class="form-group"><label>إسناد إلى</label><select id="taskAssignTo" required></select></div>
                <button type="submit" class="btn-primary">إضافة المهمة</button>
            </form>
            <div class="list-section">
                <div class="list-title">المهام الحالية</div>
                <div class="items-container" id="tasksList"></div>
            </div>
        </div>`;

    document.getElementById('createUserForm').addEventListener('submit', createUser);
    document.getElementById('addTaskForm').addEventListener('submit', addTask);
    document.getElementById('uploadFileForm').addEventListener('submit', uploadFile);
    document.getElementById('attendanceForm').addEventListener('submit', saveAttendance);
    document.getElementById('attendanceDate').value = new Date().toISOString().split('T')[0];

    loadUsers();
    loadTasks();
    setInterval(loadUsers, 5000);
    setInterval(loadTasks, 5000);
}

async function createUser(e) {
    e.preventDefault();
    const username = document.getElementById('newUsername').value;
    const password = document.getElementById('newPassword').value;
    const msgDiv = document.getElementById('createUserMsg');

    try {
        const res = await fetch(BASE_URL + '/users', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username, password, role: 'supervisor' }) });
        if (res.ok) {
            msgDiv.className = 'message success';
            msgDiv.textContent = '✓ تم إنشاء الموظف بنجاح';
            document.getElementById('createUserForm').reset();
            loadUsers();
        } else {
            const data = await res.json();
            msgDiv.className = 'message error';
            msgDiv.textContent = '✗ ' + data.error;
        }
    } catch (error) {
        msgDiv.className = 'message error';
        msgDiv.textContent = '✗ خطأ: ' + error.message;
    }
}

async function loadUsers() {
    try {
        const res = await fetch(BASE_URL + '/users');
        if (!res.ok) return;
        const users = await res.json();
        const list = document.getElementById('usersList');
        const select = document.getElementById('taskAssignTo');

        if (users.length === 0) {
            list.innerHTML = '<div class="empty-state"><i class="fas fa-inbox"></i><p>لا توجد موظفون</p></div>';
        } else {
            list.innerHTML = users.map(u => `
                <div class="user-card">
                    <div class="item-info">
                        <div class="item-name">${u.username}</div>
                        <div class="item-desc">ID: ${u.id}</div>
                    </div>
                    <div class="user-actions">
                        <span class="badge ${u.role === 'admin' ? 'badge-admin' : 'badge-supervisor'}">${u.role === 'admin' ? 'مسؤول' : 'موظف'}</span>
                        <a href="/employee/${u.id}/files" target="_blank" style="color:#4f46e5;text-decoration:none;font-weight:600;">عرض الملفات</a>
                        ${u.role !== 'admin' ? `<button class="btn-delete" onclick="deleteUser(${u.id})">حذف</button>` : ''}
                    </div>
                </div>`).join('');
        }

        select.innerHTML = '<option value="">-- اختر موظف --</option>' + users.filter(u => u.role !== 'admin').map(u => `<option value="${u.id}">${u.username}</option>`).join('');
        const uploadSelect = document.getElementById('uploadToUser');
        if (uploadSelect) {
            uploadSelect.innerHTML = '<option value="">-- اختر موظف --</option>' + users.filter(u => u.role !== 'admin').map(u => `<option value="${u.id}">${u.username}</option>`).join('');
        }
        const attendanceSelect = document.getElementById('attendanceUser');
        if (attendanceSelect) {
            attendanceSelect.innerHTML = '<option value="">-- اختر موظف --</option>' + users.filter(u => u.role !== 'admin').map(u => `<option value="${u.id}">${u.username}</option>`).join('');
        }
    } catch (error) {
        console.error('Load users error:', error);
    }
}

async function deleteUser(userId) {
    if (!confirm('هل أنت متأكد أنك تريد حذف هذا الموظف؟')) return;
    try {
        const res = await fetch(BASE_URL + '/users/' + userId, { method: 'DELETE' });
        if (res.ok) {
            loadUsers();
        } else {
            const data = await res.json();
            alert(data.error || 'فشل حذف الموظف');
        }
    } catch (error) {
        console.error('Delete user error:', error);
        alert('حدث خطأ أثناء الحذف');
    }
}

async function saveAttendance(e) {
    e.preventDefault();
    const userId = document.getElementById('attendanceUser').value;
    const attendanceDate = document.getElementById('attendanceDate').value;
    const status = document.getElementById('attendanceStatus').value;
    const msgDiv = document.getElementById('attendanceMsg');

    if (!userId || !attendanceDate) {
        msgDiv.className = 'message error';
        msgDiv.textContent = 'اختر موظفًا وتاريخًا أولاً';
        return;
    }

    try {
        const res = await fetch(BASE_URL + '/attendance', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ user_id: parseInt(userId), attendance_date: attendanceDate, status })
        });
        if (res.ok) {
            msgDiv.className = 'message success';
            msgDiv.textContent = '✓ تم حفظ حالة الحضور/الغياب بنجاح';
            document.getElementById('attendanceForm').reset();
            document.getElementById('attendanceDate').value = new Date().toISOString().split('T')[0];
        } else {
            const data = await res.json();
            msgDiv.className = 'message error';
            msgDiv.textContent = '✗ ' + (data.error || 'فشل حفظ الحالة');
        }
    } catch (error) {
        msgDiv.className = 'message error';
        msgDiv.textContent = '✗ خطأ: ' + error.message;
    }
}

async function addTask(e) {
    e.preventDefault();
    const title = document.getElementById('taskTitle').value;
    const description = document.getElementById('taskDesc').value;
    const assigned_to = document.getElementById('taskAssignTo').value;
    const msgDiv = document.getElementById('addTaskMsg');

    try {
        const res = await fetch(BASE_URL + '/tasks', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ title, description, assigned_to: parseInt(assigned_to) }) });
        if (res.ok) {
            msgDiv.className = 'message success';
            msgDiv.textContent = '✓ تم إضافة المهمة بنجاح';
            document.getElementById('addTaskForm').reset();
            loadTasks();
        } else {
            const data = await res.json();
            msgDiv.className = 'message error';
            msgDiv.textContent = '✗ ' + data.error;
        }
    } catch (error) {
        msgDiv.className = 'message error';
        msgDiv.textContent = '✗ خطأ: ' + error.message;
    }
}

async function uploadFile(e) {
    e.preventDefault();
    const userId = document.getElementById('uploadToUser').value;
    const fileInput = document.getElementById('uploadFileInput');
    const msgDiv = document.getElementById('uploadFileMsg');

    if (!userId) {
        msgDiv.className = 'message error';
        msgDiv.textContent = 'اختر موظفًا لرفع الملف';
        return;
    }
    if (!fileInput.files.length) {
        msgDiv.className = 'message error';
        msgDiv.textContent = 'اختر ملفًا للرفع';
        return;
    }

    const fd = new FormData();
    fd.append('file', fileInput.files[0]);

    try {
        const res = await fetch(BASE_URL + '/users/' + userId + '/files', { method: 'POST', body: fd, credentials: 'same-origin' });
        if (res.ok) {
            msgDiv.className = 'message success';
            msgDiv.textContent = '✓ تم رفع الملف بنجاح';
            document.getElementById('uploadFileForm').reset();
            loadUsers();
        } else {
            const data = await res.json();
            msgDiv.className = 'message error';
            msgDiv.textContent = '✗ ' + (data.error || 'فشل الرفع');
        }
    } catch (error) {
        msgDiv.className = 'message error';
        msgDiv.textContent = '✗ خطأ: ' + error.message;
    }
}

async function loadTasks() {
    try {
        const res = await fetch(BASE_URL + '/tasks');
        if (!res.ok) return;
        const tasks = await res.json();
        const list = document.getElementById('tasksList');
        if (tasks.length === 0) {
            list.innerHTML = '<div class="empty-state"><i class="fas fa-clipboard"></i><p>لا توجد مهام</p></div>';
        } else {
            list.innerHTML = tasks.map(t => `
                <div class="task-card">
                    <div class="item-info">
                        <div class="item-name">${t.title}</div>
                        <div class="item-desc">${t.description || 'بدون وصف'} | ${t.assigned_to_username || 'غير محدد'}</div>
                    </div>
                    <span class="badge ${t.status === 'done' ? 'badge-done' : 'badge-pending'}">${t.status === 'done' ? '✓ مكتملة' : '⏳ قيد الانتظار'}</span>
                </div>`).join('');
        }
    } catch (error) {
        console.error('Load tasks error:', error);
    }
}

async function loadEmployeeDashboard() {
    const grid = document.getElementById('mainGrid');
    grid.innerHTML = `
        <div class="card" style="grid-column: 1 / -1;">
            <div class="card-header">
                <div class="card-icon"><i class="fas fa-tasks"></i></div>
                <div>
                    <div class="card-title">مهامي</div>
                    <div class="card-subtitle">المهام المسندة إليّ</div>
                </div>
            </div>
            <div class="items-container" id="myTasksList"></div>
            <div style="margin-top:20px;">
                <form id="uploadMyFileForm" enctype="multipart/form-data">
                    <div id="uploadMyFileMsg"></div>
                    <div class="form-group"><label>رفع ملف عملي</label><input type="file" id="uploadMyFileInput" required></div>
                    <button type="submit" class="btn-primary">رفع الملف</button>
                </form>
            </div>
            <div style="margin-top:20px;">
                <details open style="border:1px solid #e5e7eb; border-radius:12px; padding:12px 14px; background:#f9fafb;">
                    <summary style="cursor:pointer; font-weight:700; color:#333;">ملفاتي</summary>
                    <div style="margin-top:12px;"><div id="myFilesList"></div></div>
                </details>
            </div>
            <div style="margin-top:20px; display:grid; grid-template-columns:repeat(auto-fit, minmax(220px, 1fr)); gap:14px;">
                <div style="border:1px solid #e5e7eb; border-radius:12px; padding:14px; background:#fff;"><div style="font-weight:700; color:#333; margin-bottom:8px;">ملفات المدير</div><div id="managerFilesList"></div></div>
                <div style="border:1px solid #e5e7eb; border-radius:12px; padding:14px; background:#fff;"><div style="font-weight:700; color:#333; margin-bottom:8px;">أيام الحضور</div><div id="attendanceList"></div></div>
                <div style="border:1px solid #e5e7eb; border-radius:12px; padding:14px; background:#fff;"><div style="font-weight:700; color:#333; margin-bottom:8px;">الملفات المكتملة</div><div id="completedFilesList"></div></div>
            </div>
        </div>`;

    document.getElementById('uploadMyFileForm').addEventListener('submit', async function(e) {
        e.preventDefault();
        const fileInput = document.getElementById('uploadMyFileInput');
        const msgDiv = document.getElementById('uploadMyFileMsg');
        if (!fileInput.files.length) {
            msgDiv.className = 'message error';
            msgDiv.textContent = 'اختر ملفًا للرفع';
            return;
        }
        const fd = new FormData();
        fd.append('file', fileInput.files[0]);
        try {
            const res = await fetch(BASE_URL + '/users/' + window.CURRENT_USER_ID + '/files', { method: 'POST', body: fd, credentials: 'same-origin' });
            if (res.ok) {
                msgDiv.className = 'message success';
                msgDiv.textContent = '✓ تم رفع الملف بنجاح';
                document.getElementById('uploadMyFileForm').reset();
                loadMyTasks();
                loadMyFilesList();
            } else {
                const data = await res.json();
                msgDiv.className = 'message error';
                msgDiv.textContent = '✗ ' + (data.error || 'فشل الرفع');
            }
        } catch (error) {
            msgDiv.className = 'message error';
            msgDiv.textContent = '✗ خطأ: ' + error.message;
        }
    });

    loadMyTasks();
    loadMyFilesList();
    loadEmployeeSidebar();
    setInterval(loadMyTasks, 5000);
    setInterval(loadMyFilesList, 5000);
    setInterval(loadEmployeeSidebar, 5000);
}

async function loadEmployeeSidebar() {
    try {
        const filesRes = await fetch(BASE_URL + '/users/' + window.CURRENT_USER_ID + '/files');
        const attendanceRes = await fetch(BASE_URL + '/users/' + window.CURRENT_USER_ID + '/attendance');
        if (!filesRes.ok || !attendanceRes.ok) return;
        const files = await filesRes.json();
        const attendance = await attendanceRes.json();
        const managerFiles = files.filter(f => f.uploaded_by_role === 'admin');
        const completedFiles = files.filter(f => f.uploaded_by_id === window.CURRENT_USER_ID);
        const managerList = document.getElementById('managerFilesList');
        const attendanceList = document.getElementById('attendanceList');
        const completedList = document.getElementById('completedFilesList');

        managerList.innerHTML = managerFiles.length ? '<ul style="padding-right:16px; margin:0;">' + managerFiles.map(f => `<li style="margin-bottom:6px;"><a href="${f.url}" download="${f.filename}" style="color:#4f46e5;">${f.filename}</a></li>`).join('') + '</ul>' : '<div class="empty-state"><i class="fas fa-file-alt"></i><p>لا توجد ملفات من المدير</p></div>';
        attendanceList.innerHTML = attendance.length ? '<ul style="padding-right:16px; margin:0;">' + attendance.slice(0, 7).map(a => `<li style="margin-bottom:6px;">${a.attendance_date} — ${a.check_in_time || '-'} إلى ${a.check_out_time || '-'}</li>`).join('') + '</ul>' : '<div class="empty-state"><i class="fas fa-calendar-check"></i><p>لا توجد سجل حضور بعد</p></div>';
        completedList.innerHTML = completedFiles.length ? '<ul style="padding-right:16px; margin:0;">' + completedFiles.map(f => `<li style="margin-bottom:6px;"><a href="${f.url}" download="${f.filename}" style="color:#4f46e5;">${f.filename}</a></li>`).join('') + '</ul>' : '<div class="empty-state"><i class="fas fa-check-circle"></i><p>لا توجد ملفات مكتملة بعد</p></div>';
    } catch (error) {
        console.error('Load employee sidebar error:', error);
    }
}

async function loadMyFilesList() {
    try {
        const res = await fetch(BASE_URL + '/users/' + window.CURRENT_USER_ID + '/files');
        if (!res.ok) return;
        const files = await res.json();
        const list = document.getElementById('myFilesList');
        if (!files.length) {
            list.innerHTML = '<div class="empty-state"><i class="fas fa-file-alt"></i><p>لا توجد ملفات بعد</p></div>';
            return;
        }
        list.innerHTML = '<ul style="padding-right:20px; margin:0;">' + files.map(f => `<li style="margin-bottom:8px;"><a href="${f.url}" download="${f.filename}" style="color:#4f46e5;">${f.filename}</a></li>`).join('') + '</ul>';
    } catch (error) {
        console.error('Load my files error:', error);
    }
}

async function loadMyTasks() {
    try {
        const res = await fetch(BASE_URL + '/tasks');
        if (!res.ok) return;
        const tasks = await res.json();
        const list = document.getElementById('myTasksList');
        if (tasks.length === 0) {
            list.innerHTML = '<div class="empty-state"><i class="fas fa-clipboard"></i><p>لا توجد مهام مسندة إليك</p></div>';
        } else {
            list.innerHTML = tasks.map(t => `
                <div class="task-card">
                    <div class="item-info">
                        <div class="item-name">${t.title}</div>
                        <div class="item-desc">${t.description || 'بدون وصف'}</div>
                    </div>
                    <div style="display:flex; gap:10px; align-items:center;">
                        <span class="badge ${t.status === 'done' ? 'badge-done' : 'badge-pending'}">${t.status === 'done' ? '✓ مكتملة' : '⏳ قيد الانتظار'}</span>
                        ${t.status === 'pending' ? `<button class="btn-small" onclick="markDone(${t.id})">إكمال</button>` : ''}
                    </div>
                </div>`).join('');
        }
    } catch (error) {
        console.error('Load my tasks error:', error);
    }
}

async function markDone(taskId) {
    try {
        const res = await fetch(BASE_URL + '/tasks/' + taskId + '/done', { method: 'PUT' });
        if (res.ok) {
            loadMyTasks();
        }
    } catch (error) {
        console.error('Mark done error:', error);
    }
}

loadSavedLogin();
checkAuth();
