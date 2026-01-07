const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// MySQL Connection Pool - Aiven Cloud Database
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: {
        rejectUnauthorized: false
    },
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Initialize database tables
async function initDatabase() {
    try {
        const connection = await pool.getConnection();

        // Create users table
        await connection.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(100) NOT NULL,
        avatar VARCHAR(255),
        student_id VARCHAR(50),
        major VARCHAR(100),
        department VARCHAR(100),
        program VARCHAR(100),
        gpa DECIMAL(3,2),
        level INT,
        mode VARCHAR(20) DEFAULT 'student',
        is_verified BOOLEAN DEFAULT FALSE,
        is_onboarding_complete BOOLEAN DEFAULT FALSE,
        enrolled_courses TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

        // Create tasks table
        await connection.execute(`
      CREATE TABLE IF NOT EXISTS tasks (
        id VARCHAR(50) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        course VARCHAR(100),
        priority VARCHAR(20) DEFAULT 'low',
        completed BOOLEAN DEFAULT FALSE,
        description TEXT,
        user_id VARCHAR(50),
        due_date DATETIME,
        notification_id INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

        // Insert default tasks if table is empty
        const [rows] = await connection.execute('SELECT COUNT(*) as count FROM tasks');
        if (rows[0].count === 0) {
            await connection.execute(`
                INSERT INTO tasks (id, title, course, priority, completed, description) VALUES
                ('1', 'Complete Data Structures Assignment', 'Computer Science', 'high', FALSE, 'Implement binary search tree'),
                ('2', 'Read Chapter 5 - Algorithms', 'Computer Science', 'medium', FALSE, 'Study sorting algorithms'),
                ('3', 'Math Problem Set 7', 'Mathematics', 'low', FALSE, 'Linear algebra exercises'),
                ('4', 'Physics Lab Report', 'Physics', 'high', FALSE, 'Write lab report')
            `);
            console.log('✅ Default tasks inserted');
        }

        // Create verification codes table
        await connection.execute(`
      CREATE TABLE IF NOT EXISTS verification_codes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(100) NOT NULL,
        code VARCHAR(10) NOT NULL,
        type VARCHAR(20) NOT NULL,
        expires_at DATETIME NOT NULL,
        used BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_email (email),
        INDEX idx_code (code)
      )
    `);

        // Try to add new columns if they don't exist (for existing tables)
        try { await connection.execute('ALTER TABLE users ADD COLUMN program VARCHAR(100)'); } catch (e) { }
        try { await connection.execute('ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE'); } catch (e) { }

        connection.release();
        // Create announcements table
        await connection.execute(`
            CREATE TABLE IF NOT EXISTS announcements (
                id VARCHAR(50) PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                message TEXT,
                date DATETIME DEFAULT CURRENT_TIMESTAMP,
                type ENUM('general', 'exam', 'assignment', 'event') DEFAULT 'general',
                is_read BOOLEAN DEFAULT FALSE,
                course_id VARCHAR(50)
            )
        `);

        // Create schedule table
        await connection.execute(`
            CREATE TABLE IF NOT EXISTS schedule_events (
                id VARCHAR(50) PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                start_time DATETIME NOT NULL,
                end_time DATETIME NOT NULL,
                location VARCHAR(100),
                instructor VARCHAR(100),
                course_id VARCHAR(50),
                description TEXT,
                type VARCHAR(20) DEFAULT 'lecture'
            )
        `);

        // Create courses table
        await connection.execute(`
            CREATE TABLE IF NOT EXISTS courses (
                id VARCHAR(50) PRIMARY KEY,
                code VARCHAR(20) NOT NULL,
                name VARCHAR(100) NOT NULL,
                category VARCHAR(50),
                credit_hours INT,
                professors JSON,
                description TEXT,
                schedule JSON,
                content JSON,
                assignments JSON,
                exams JSON
            )
        `);

        // Seed courses if empty
        const [courseRows] = await connection.execute('SELECT count(*) as count FROM courses');
        if (courseRows[0].count === 0) {
            console.log('🌱 Seeding courses...');
            const courses = [
                {
                    id: '1', code: 'COMP101', name: 'Introduction to Computer Science', category: 'comp', creditHours: 4,
                    professors: JSON.stringify(['Dr. Smith']),
                    description: 'An introductory course to computer science concepts including programming fundamentals, data structures, and algorithms.',
                    schedule: JSON.stringify([
                        { day: 'Monday', time: '10:00 AM - 11:30 AM', location: 'Room 204' },
                        { day: 'Wednesday', time: '10:00 AM - 11:30 AM', location: 'Room 204' },
                        { day: 'Friday', time: '10:00 AM - 11:30 AM', location: 'Lab 101' }
                    ]),
                    content: JSON.stringify([
                        { week: 1, topic: 'Introduction to Programming', description: 'Basic concepts of programming and problem-solving' },
                        { week: 2, topic: 'Variables and Data Types', description: 'Understanding variables, data types, and memory management' }
                    ]),
                    assignments: JSON.stringify([
                        { id: '1', title: 'Hello World Program', dueDate: new Date(Date.now() + 7 * 86400000).toISOString(), maxScore: 100, description: 'Write a simple program that displays "Hello, World!"' }
                    ]),
                    exams: JSON.stringify([
                        { id: '1', title: 'Midterm Exam', date: new Date(Date.now() + 30 * 86400000).toISOString(), format: 'Written and Practical', gradingBreakdown: 'Theory: 60%, Practical: 40%' }
                    ])
                },
                {
                    id: '2', code: 'MATH101', name: 'Calculus I', category: 'math', creditHours: 4,
                    professors: JSON.stringify(['Dr. Brown']),
                    description: 'An introductory course to calculus covering limits, derivatives, and integrals.',
                    schedule: JSON.stringify([
                        { day: 'Tuesday', time: '2:00 PM - 3:30 PM', location: 'Room 305' },
                        { day: 'Thursday', time: '2:00 PM - 3:30 PM', location: 'Room 305' }
                    ]),
                    content: JSON.stringify([
                        { week: 1, topic: 'Limits and Continuity', description: 'Understanding limits and continuity of functions' },
                        { week: 2, topic: 'Derivatives', description: 'Introduction to derivatives and differentiation rules' }
                    ]),
                    assignments: JSON.stringify([
                        { id: '2', title: 'Derivative Problems Set', dueDate: new Date(Date.now() + 5 * 86400000).toISOString(), maxScore: 50, description: 'Solve problems on differentiation' }
                    ]),
                    exams: JSON.stringify([
                        { id: '2', title: 'Calculus Midterm', date: new Date(Date.now() + 28 * 86400000).toISOString(), format: 'Written Exam', gradingBreakdown: 'Problem Solving: 70%, Theory: 30%' }
                    ])
                },
                {
                    id: '3', code: 'PHYS101', name: 'Physics I', category: 'phys', creditHours: 4,
                    professors: JSON.stringify(['Prof. Johnson']),
                    description: 'Mechanics and Thermodynamics covering motion, forces, energy, and heat.',
                    schedule: JSON.stringify([
                        { day: 'Monday', time: '2:00 PM - 3:30 PM', location: 'Room 201' },
                        { day: 'Wednesday', time: '2:00 PM - 3:30 PM', location: 'Room 201' },
                        { day: 'Friday', time: '2:00 PM - 4:00 PM', location: 'Lab 102' }
                    ]),
                    content: JSON.stringify([
                        { week: 1, topic: 'Kinematics', description: 'Study of motion without considering forces' },
                        { week: 2, topic: 'Newton\'s Laws', description: 'Forces and their effects on motion' }
                    ]),
                    assignments: JSON.stringify([
                        { id: '3', title: 'Force Analysis Problems', dueDate: new Date(Date.now() + 6 * 86400000).toISOString(), maxScore: 75, description: 'Analyze forces in various scenarios' }
                    ]),
                    exams: JSON.stringify([
                        { id: '3', title: 'Physics Midterm', date: new Date(Date.now() + 32 * 86400000).toISOString(), format: 'Written + Lab Practical', gradingBreakdown: 'Theory: 50%, Practical: 50%' }
                    ])
                },
                {
                    id: '4', code: 'COMP201', name: 'Data Structures', category: 'comp', creditHours: 4,
                    professors: JSON.stringify(['Dr. Smith']),
                    description: 'Advanced data structures including trees, graphs, and hash tables.',
                    schedule: JSON.stringify([
                        { day: 'Tuesday', time: '10:00 AM - 11:30 AM', location: 'Room 203' },
                        { day: 'Thursday', time: '10:00 AM - 11:30 AM', location: 'Room 203' }
                    ]),
                    content: JSON.stringify([
                        { week: 1, topic: 'Arrays and Linked Lists', description: 'Linear data structures' },
                        { week: 2, topic: 'Stacks and Queues', description: 'LIFO and FIFO data structures' }
                    ]),
                    assignments: JSON.stringify([
                        { id: '4', title: 'Binary Tree Implementation', dueDate: new Date(Date.now() + 8 * 86400000).toISOString(), maxScore: 100, description: 'Implement binary search tree with insert, delete, and search operations' }
                    ]),
                    exams: JSON.stringify([
                        { id: '4', title: 'Data Structures Exam', date: new Date(Date.now() + 35 * 86400000).toISOString(), format: 'Written + Coding', gradingBreakdown: 'Theory: 40%, Coding: 60%' }
                    ])
                }
            ];

            for (const course of courses) {
                await connection.execute(
                    'INSERT INTO courses (id, code, name, category, credit_hours, professors, description, schedule, content, assignments, exams) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    [course.id, course.code, course.name, course.category, course.creditHours, course.professors, course.description, course.schedule, course.content, course.assignments, course.exams]
                );
            }
        }

        console.log('✅ Database tables initialized');
    } catch (error) {
        console.error('❌ Database init error:', error.message);
    }
}

// ============ AUTH ROUTES ============

// Login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const [rows] = await pool.execute(
            'SELECT * FROM users WHERE email = ? AND password = ?',
            [email, password]
        );

        if (rows.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = formatUser(rows[0]);
        console.log(`✅ Login successful: ${email}`);
        res.json({ success: true, user });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

// Register
app.post('/api/auth/register', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Check if user exists
        const [existing] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
        if (existing.length > 0) {
            return res.status(409).json({ error: 'User already exists' });
        }

        const id = Date.now().toString();
        const studentId = `STU${id}`;
        const avatar = `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}`;

        await pool.execute(`
      INSERT INTO users (id, name, email, password, avatar, student_id, mode, is_onboarding_complete)
      VALUES (?, ?, ?, ?, ?, ?, 'student', FALSE)
    `, [id, name, email, password, avatar, studentId]);

        const user = {
            id,
            name,
            email,
            avatar,
            studentId,
            mode: 'student',
            isOnboardingComplete: false,
            enrolledCourses: []
        };

        console.log(`✅ Registration successful: ${email}`);
        res.json({ success: true, user });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

// Get User
app.get('/api/users/:email', async (req, res) => {
    try {
        const { email } = req.params;
        const [rows] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);

        if (rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const user = formatUser(rows[0]);
        res.json({ success: true, user });
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
});

// Update User
app.put('/api/users/:email', async (req, res) => {
    try {
        const { email } = req.params;
        const { name, avatar, major, department, gpa, level, mode, isOnboardingComplete, enrolledCourses } = req.body;

        const coursesStr = Array.isArray(enrolledCourses) ? enrolledCourses.join(',') : '';

        await pool.execute(`
      UPDATE users SET
        name = ?,
        avatar = ?,
        major = ?,
        department = ?,
        gpa = ?,
        level = ?,
        mode = ?,
        is_onboarding_complete = ?,
        enrolled_courses = ?
      WHERE email = ?
    `, [name, avatar, major, department, gpa, level, mode, isOnboardingComplete ? 1 : 0, coursesStr, email]);

        // Return the updated user
        const [rows] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);
        const user = rows.length > 0 ? formatUser(rows[0]) : null;

        console.log(`✅ User updated: ${email}`);
        res.json({ success: true, user });
    } catch (error) {
        console.error('Update user error:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
});

// Change Password
app.post('/api/auth/change-password', async (req, res) => {
    try {
        const { email, currentPassword, newPassword } = req.body;

        const [rows] = await pool.execute(
            'SELECT id FROM users WHERE email = ? AND password = ?',
            [email, currentPassword]
        );

        if (rows.length === 0) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }

        await pool.execute('UPDATE users SET password = ? WHERE email = ?', [newPassword, email]);

        console.log(`✅ Password changed: ${email}`);
        res.json({ success: true });
    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ error: 'Failed to change password' });
    }
});

// Delete all users (for development/testing)
app.delete('/api/users', async (req, res) => {
    try {
        await pool.execute('DELETE FROM users');
        console.log('🗑️ All users deleted');
        res.json({ success: true, message: 'All users deleted' });
    } catch (error) {
        console.error('Delete all users error:', error);
        res.status(500).json({ error: 'Failed to delete users' });
    }
});

// ============ VERIFICATION CODES ============

// Store verification code (called from frontend after sending email)
app.post('/api/auth/store-code', async (req, res) => {
    try {
        const { email, code, type } = req.body;

        // Delete any existing codes for this email and type
        await pool.execute('DELETE FROM verification_codes WHERE email = ? AND type = ?', [email, type]);

        // Insert new code with 10 minute expiry
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
        await pool.execute(
            'INSERT INTO verification_codes (email, code, type, expires_at) VALUES (?, ?, ?, ?)',
            [email, code, type, expiresAt]
        );

        console.log(`✅ Verification code stored for: ${email}`);
        res.json({ success: true });
    } catch (error) {
        console.error('Store code error:', error);
        res.status(500).json({ error: 'Failed to store code' });
    }
});

// Verify code
app.post('/api/auth/verify-code', async (req, res) => {
    try {
        const { email, code, type } = req.body;

        const [rows] = await pool.execute(
            'SELECT * FROM verification_codes WHERE email = ? AND code = ? AND type = ? AND used = FALSE AND expires_at > NOW()',
            [email, code, type]
        );

        if (rows.length === 0) {
            return res.status(400).json({ error: 'Invalid or expired code' });
        }

        // Mark code as used
        await pool.execute('UPDATE verification_codes SET used = TRUE WHERE id = ?', [rows[0].id]);

        // If registration verification, mark user as verified
        if (type === 'registration') {
            await pool.execute('UPDATE users SET is_verified = TRUE WHERE email = ?', [email]);
        }

        console.log(`✅ Code verified for: ${email}`);
        res.json({ success: true, verified: true });
    } catch (error) {
        console.error('Verify code error:', error);
        res.status(500).json({ error: 'Failed to verify code' });
    }
});

// Reset password (using email only - after verification)
app.post('/api/auth/reset-password', async (req, res) => {
    try {
        const { email, newPassword } = req.body;

        // Just check user exists
        const [users] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Update password directly (verification was done on previous page)
        await pool.execute('UPDATE users SET password = ? WHERE email = ?', [newPassword, email]);

        // Clean up any verification codes
        await pool.execute('DELETE FROM verification_codes WHERE email = ?', [email]);

        console.log(`✅ Password reset for: ${email}`);
        res.json({ success: true });
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(500).json({ error: 'Failed to reset password' });
    }
});

// ============ TASKS (MySQL Persistent Storage) ============

// Helper function to format task data
function formatTask(row) {
    return {
        id: row.id,
        title: row.title,
        course: row.course,
        priority: row.priority,
        completed: row.completed === 1,
        description: row.description,
        userId: row.user_id,
        dueDate: row.due_date,
        notificationId: row.notification_id
    };
}

// Get all tasks
app.get('/api/tasks', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM tasks ORDER BY created_at DESC');
        const tasks = rows.map(formatTask);
        res.json({ success: true, tasks });
    } catch (error) {
        console.error('Get tasks error:', error);
        res.status(500).json({ error: 'Failed to get tasks' });
    }
});

// Add task
app.post('/api/tasks', async (req, res) => {
    try {
        const { title, course, priority, description, userId, dueDate, notificationId } = req.body;
        const id = Date.now().toString();

        await pool.execute(`
            INSERT INTO tasks (id, title, course, priority, completed, description, user_id, due_date, notification_id)
            VALUES (?, ?, ?, ?, FALSE, ?, ?, ?, ?)
        `, [id, title, course || 'General', priority || 'low', description || '', userId || null, dueDate || null, notificationId || null]);

        const task = {
            id,
            title,
            course: course || 'General',
            priority: priority || 'low',
            completed: false,
            description: description || '',
            userId,
            dueDate,
            notificationId
        };

        console.log(`✅ Task added to DB: ${title}`);
        res.json({ success: true, task });
    } catch (error) {
        console.error('Add task error:', error);
        res.status(500).json({ error: 'Failed to add task' });
    }
});

// Update task
app.put('/api/tasks/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { title, course, priority, completed, description, dueDate } = req.body;

        await pool.execute(`
            UPDATE tasks SET
                title = COALESCE(?, title),
                course = COALESCE(?, course),
                priority = COALESCE(?, priority),
                completed = COALESCE(?, completed),
                description = COALESCE(?, description),
                due_date = COALESCE(?, due_date)
            WHERE id = ?
        `, [title, course, priority, completed, description, dueDate, id]);

        // Get updated task
        const [rows] = await pool.execute('SELECT * FROM tasks WHERE id = ?', [id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Task not found' });
        }

        console.log(`✅ Task updated in DB: ${id}`);
        res.json({ success: true, task: formatTask(rows[0]) });
    } catch (error) {
        console.error('Update task error:', error);
        res.status(500).json({ error: 'Failed to update task' });
    }
});

// Toggle task completion
app.patch('/api/tasks/:id/toggle', async (req, res) => {
    try {
        const { id } = req.params;

        await pool.execute('UPDATE tasks SET completed = NOT completed WHERE id = ?', [id]);

        // Get updated task
        const [rows] = await pool.execute('SELECT * FROM tasks WHERE id = ?', [id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Task not found' });
        }

        console.log(`✅ Task toggled in DB: ${id} -> ${rows[0].completed}`);
        res.json({ success: true, task: formatTask(rows[0]) });
    } catch (error) {
        console.error('Toggle task error:', error);
        res.status(500).json({ error: 'Failed to toggle task' });
    }
});

// Delete task
app.delete('/api/tasks/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.execute('DELETE FROM tasks WHERE id = ?', [id]);
        console.log(`✅ Task deleted from DB: ${id}`);
        res.json({ success: true });
    } catch (error) {
        console.error('Delete task error:', error);
        res.status(500).json({ error: 'Failed to delete task' });
    }
});

// Delete all tasks (for development/testing)
app.delete('/api/tasks', async (req, res) => {
    try {
        await pool.execute('DELETE FROM tasks');
        console.log('🗑️ All tasks deleted');
        res.json({ success: true, message: 'All tasks deleted' });
    } catch (error) {
        console.error('Delete all tasks error:', error);
        res.status(500).json({ error: 'Failed to delete tasks' });
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Helper function to format user data
function formatUser(row) {
    const coursesStr = row.enrolled_courses || '';
    const courses = coursesStr ? coursesStr.split(',').filter(s => s) : [];

    return {
        id: row.id,
        name: row.name,
        email: row.email,
        avatar: row.avatar,
        studentId: row.student_id,
        major: row.major,
        department: row.department,
        gpa: row.gpa ? parseFloat(row.gpa) : null,
        level: row.level,
        mode: row.mode || 'student',
        isOnboardingComplete: row.is_onboarding_complete === 1,
        enrolledCourses: courses
    };
}

// ============ ANNOUNCEMENTS ============

app.get('/api/announcements', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM announcements ORDER BY date DESC');
        res.json({ success: true, announcements: rows });
    } catch (error) {
        console.error('Get announcements error:', error);
        res.status(500).json({ error: 'Failed to get announcements' });
    }
});

app.post('/api/announcements', async (req, res) => {
    try {
        const { title, message, type, courseId } = req.body;
        const id = Date.now().toString();
        await pool.execute(
            'INSERT INTO announcements (id, title, message, type, course_id) VALUES (?, ?, ?, ?, ?)',
            [id, title, message, type || 'general', courseId || null]
        );
        res.json({ success: true, id });
    } catch (error) {
        console.error('Add announcement error:', error);
        res.status(500).json({ error: 'Failed to add announcement' });
    }
});

app.patch('/api/announcements/:id/read', async (req, res) => {
    try {
        await pool.execute('UPDATE announcements SET is_read = TRUE WHERE id = ?', [req.params.id]);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Failed to update announcement' });
    }
});

// ============ SCHEDULE ============

app.get('/api/schedule', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM schedule_events ORDER BY start_time ASC');
        res.json({ success: true, events: rows });
    } catch (error) {
        console.error('Get schedule error:', error);
        res.status(500).json({ error: 'Failed to get schedule' });
    }
});

app.post('/api/schedule', async (req, res) => {
    try {
        const { title, startTime, endTime, location, instructor, courseId, description, type } = req.body;
        const id = Date.now().toString();
        await pool.execute(
            'INSERT INTO schedule_events (id, title, start_time, end_time, location, instructor, course_id, description, type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [id, title, startTime, endTime, location, instructor, courseId, description, type || 'lecture']
        );
        res.json({ success: true, id });
    } catch (error) {
        console.error('Add schedule error:', error);
        res.status(500).json({ error: 'Failed to add schedule' });
    }
});

// ============ COURSES ============

app.get('/api/courses', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM courses');
        // Parse JSON fields
        const courses = rows.map(course => ({
            ...course,
            professors: JSON.parse(course.professors || '[]'),
            schedule: JSON.parse(course.schedule || '[]'),
            content: JSON.parse(course.content || '[]'),
            assignments: JSON.parse(course.assignments || '[]'),
            exams: JSON.parse(course.exams || '[]'),
        }));
        res.json({ success: true, courses });
    } catch (error) {
        console.error('Get courses error:', error);
        res.status(500).json({ error: 'Failed to get courses' });
    }
});

app.get('/api/courses/:id', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM courses WHERE id = ?', [req.params.id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Course not found' });
        }
        const course = rows[0];
        // Parse JSON fields
        res.json({
            success: true,
            course: {
                ...course,
                professors: JSON.parse(course.professors || '[]'),
                schedule: JSON.parse(course.schedule || '[]'),
                content: JSON.parse(course.content || '[]'),
                assignments: JSON.parse(course.assignments || '[]'),
                exams: JSON.parse(course.exams || '[]'),
            }
        });
    } catch (error) {
        console.error('Get course by id error:', error);
        res.status(500).json({ error: 'Failed to get course' });
    }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    await initDatabase();
});
