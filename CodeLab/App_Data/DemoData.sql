-- CodeLab demo data: a fully populated database for demos. Self-contained: run Schema.sql, then this file.
-- It includes everything Seed.sql adds (the admin, tutor and learner accounts, the tutor applicants,
-- the three landing-page courses and the badge catalog), so Seed.sql is not needed any more.
-- Safe to re-run: every row is only inserted if it is missing, and the whole script is one
-- transaction, so an error rolls everything back and leaves the database as it was.
-- Never run this on a real deployment: the accounts below use public passwords.
--
-- Accounts (admin: Admin@123, tutors: Tutor@123, learners: Learner@123):
--   Admin     : admin
--   Tutors    : tutor (Dr. Alan Turing), grace, ada       (approved, with their own courses)
--   Applicants: helena, marcus                            (tutor applications waiting for admin review)
--   Learners  : learner (Sarah Connor), alice, ben, chloe, daniel, emma, farid, gracelee, hiro
--   Suspended : ivan (a learner an admin has suspended)
-- Profile photos and course covers are files in CodeLab/Uploads/Avatars and CodeLab/Uploads/Covers;
-- this script only stores their paths, so those files must exist on the machine that runs the site.
--
-- Rows refer to each other by looking up names, never by hard-coded Id numbers.

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.Badges', 'U') IS NULL OR COL_LENGTH('dbo.CodeSubmissions', 'AiFeedback') IS NULL
    THROW 50001, 'The tables are missing or out of date. Run Schema.sql first.', 1;

-- Password hashes made by PasswordHelper.HashPassword
DECLARE @LearnerHash NVARCHAR(255) = N'PBKDF2$100000$37zQ2kfdZ148fOYGIfD+iA==$w7QKt8ThVv0X/Ex8yqMapnaL9rHduxn/AtQG1106MTg=';
DECLARE @TutorHash   NVARCHAR(255) = N'PBKDF2$100000$FEu2YWRbd+EGiSvsO+FwuA==$P6uWyc8nseayvQ65rCeGe/YVYk18mtndKpFBZqK8K0k=';
DECLARE @AdminHash   NVARCHAR(255) = N'PBKDF2$100000$OBc+sqcmvyOf3s03wTz3zg==$za1bHIPChNws30L5gLcbVmZJUR+yTbACUOrJeiHLN8A=';
DECLARE @HelenaHash  NVARCHAR(255) = N'PBKDF2$100000$0fsSTcyDpxdQVoneFacuPw==$dqINMldOdpgvXkRgZGExxXMI3GyUwXwXRXm+wOMHcEU=';
DECLARE @MarcusHash  NVARCHAR(255) = N'PBKDF2$100000$6ef7qiDoihlguhgYukYJLg==$+FdcpHGvQCHteS1oNIy7Drjo3314xbCRqpya4+sg/4k=';

-- Course titles, used by every section below
DECLARE @tTS   NVARCHAR(200) = N'Modern TypeScript & Scalable React Patterns';
DECLARE @tAlgo NVARCHAR(200) = N'Algorithms & Discrete Math for Developers';
DECLARE @tPy   NVARCHAR(200) = N'Python Essentials: From Zero to Automated Scripts';
DECLARE @tWeb  NVARCHAR(200) = N'Web Basics: HTML and CSS';
DECLARE @tDS   NVARCHAR(200) = N'Data Structures in Python';
DECLARE @tSQL  NVARCHAR(200) = N'SQL Essentials: Query Your First Database';
DECLARE @tJS   NVARCHAR(200) = N'JavaScript Foundations: Functions and Arrays';
DECLARE @tGit  NVARCHAR(200) = N'Intro to Git and GitHub';
DECLARE @tPerl NVARCHAR(200) = N'Perl Scripting Basics';

-- =====================================
-- Users
-- =====================================
INSERT INTO dbo.Users (FullName, Username, Email, PasswordHash, Role, Status, AvatarUrl, JoinedDate, LastLogin)
SELECT v.FullName, v.Username, v.Email, v.Hash, v.Role, v.Status, v.AvatarUrl,
       DATEADD(DAY, -v.JoinedDaysAgo, SYSUTCDATETIME()),
       CASE WHEN v.LoginHoursAgo IS NULL THEN NULL ELSE DATEADD(HOUR, -v.LoginHoursAgo, SYSUTCDATETIME()) END
FROM (VALUES
    (N'System Administrator', N'admin',   N'admin@codelab.local',        @AdminHash,   N'Admin',   N'Active',    N'~/Uploads/Avatars/avatar-admin.jpg',        90, 1),
    (N'Dr. Alan Turing',      N'tutor',   N'tutor@codelab.local',        @TutorHash,   N'Tutor',   N'Active',    N'~/Uploads/Avatars/avatar-alan-turing.jpg',  80, 2),
    (N'Sarah Connor',         N'learner', N'learner@codelab.local',      @LearnerHash, N'Learner', N'Active',    N'~/Uploads/Avatars/avatar-sarah-connor.jpg', 62, 1),
    (N'Dr. Helena Zhang',     N'helena',  N'helena.zhang@codelab.local', @HelenaHash,  N'Tutor',   N'Active',    N'~/Uploads/Avatars/avatar-helena-zhang.jpg', 3, NULL),
    (N'Marcus Vance',         N'marcus',  N'marcus.vance@codelab.local', @MarcusHash,  N'Tutor',   N'Active',    N'~/Uploads/Avatars/avatar-marcus-vance.jpg', 2, NULL),
    (N'Prof. Grace Hopper', N'grace',    N'grace.hopper@codelab.local',   @TutorHash,   N'Tutor',   N'Active',    N'~/Uploads/Avatars/avatar-grace-hopper.jpg', 70, 5),
    (N'Dr. Ada Lovelace',   N'ada',      N'ada.lovelace@codelab.local',   @TutorHash,   N'Tutor',   N'Active',    N'~/Uploads/Avatars/avatar-ada-lovelace.jpg', 65, 9),
    (N'Alice Tan',          N'alice',    N'alice.tan@codelab.local',      @LearnerHash, N'Learner', N'Active',    CAST(NULL AS NVARCHAR(500)),                  60, 2),
    (N'Ben Carter',         N'ben',      N'ben.carter@codelab.local',     @LearnerHash, N'Learner', N'Active',    NULL,                                         55, 6),
    (N'Chloe Nguyen',       N'chloe',    N'chloe.nguyen@codelab.local',   @LearnerHash, N'Learner', N'Active',    NULL,                                         50, 12),
    (N'Daniel Lim',         N'daniel',   N'daniel.lim@codelab.local',     @LearnerHash, N'Learner', N'Active',    NULL,                                         45, 30),
    (N'Emma Wong',          N'emma',     N'emma.wong@codelab.local',      @LearnerHash, N'Learner', N'Active',    NULL,                                         40, 4),
    (N'Farid Rahman',       N'farid',    N'farid.rahman@codelab.local',   @LearnerHash, N'Learner', N'Active',    NULL,                                         35, 48),
    (N'Grace Lee',          N'gracelee', N'grace.lee@codelab.local',      @LearnerHash, N'Learner', N'Active',    NULL,                                         30, 3),
    (N'Hiro Tanaka',        N'hiro',     N'hiro.tanaka@codelab.local',    @LearnerHash, N'Learner', N'Active',    NULL,                                         25, 8),
    (N'Ivan Petrov',        N'ivan',     N'ivan.petrov@codelab.local',    @LearnerHash, N'Learner', N'Suspended', NULL,                                         20, 100)
) v(FullName, Username, Email, Hash, Role, Status, AvatarUrl, JoinedDaysAgo, LoginHoursAgo)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Users u WHERE u.Username = v.Username);

-- A learner that already existed from an earlier run has logged in before too
UPDATE dbo.Users SET LastLogin = DATEADD(HOUR, -1, SYSUTCDATETIME()) WHERE Username = N'learner' AND LastLogin IS NULL;

-- =====================================
-- Tutor profiles (tutor, grace and ada are approved; helena and marcus are waiting for review)
-- =====================================
INSERT INTO dbo.TutorProfiles (UserId, Qualifications, PortfolioUrl, CurriculumPitch, Bio, Specialty, Status, ApprovedDate)
SELECT u.Id, v.Qualifications, v.PortfolioUrl, v.Pitch, v.Bio, v.Specialty, v.Status,
       CASE WHEN v.Status = N'Approved' THEN DATEADD(DAY, -v.ApprovedDaysAgo, SYSUTCDATETIME()) END
FROM (VALUES
    (N'tutor', N'Ph.D. in Computer Science', N'https://portfolio.codelab.local/turing',
     N'A hands-on algorithms course: complexity, sorting, graphs and dynamic programming, each with coding challenges.',
     N'Father of modern computing and algorithm design.', N'Algorithms & Logic', N'Approved', 80),
    (N'helena', N'Ph.D. in Machine Learning; 8 years as an ML research lead.', N'https://portfolio.codelab.local/helena',
     N'Deep learning from scratch: tensors, gradient descent and backpropagation, then building and training a small transformer in PyTorch.',
     N'Passionate about making tensor operations and gradient descent easy to follow for software engineers.', N'Machine Learning & PyTorch', N'Pending', 0),
    (N'marcus', N'6 years as a staff infrastructure engineer; Certified Kubernetes Administrator.', N'https://portfolio.codelab.local/marcus',
     N'Containers to production: Docker images, Kubernetes deployments, CI/CD pipelines and GitOps, with a hands-on lab in every lesson.',
     N'Infrastructure engineer who enjoys teaching practical container orchestration and pipeline reliability.', N'Cloud Native DevOps & Kubernetes', N'Pending', 0),
    (N'grace', N'M.Sc. in Computer Science; 12 years teaching web development.', N'https://portfolio.codelab.local/grace',
     N'Practical web and database courses: HTML, CSS, SQL, each lesson with a small exercise.',
     N'Teacher who loves turning complicated ideas into short, friendly lessons.', N'Web Development & Databases', N'Approved', 60),
    (N'ada', N'Ph.D. in Mathematics; author of a Python data structures workbook.', N'https://portfolio.codelab.local/ada',
     N'Data structures in Python, from lists and stacks to linked lists, with a coding challenge per topic.',
     N'Mathematician turned programmer who enjoys explaining how data is organised.', N'Python & Data Structures', N'Approved', 55)
) v(Username, Qualifications, PortfolioUrl, Pitch, Bio, Specialty, Status, ApprovedDaysAgo)
JOIN dbo.Users u ON u.Username = v.Username
WHERE NOT EXISTS (SELECT 1 FROM dbo.TutorProfiles p WHERE p.UserId = u.Id);

-- =====================================
-- Courses: published, waiting for review, draft and locked
-- =====================================
INSERT INTO dbo.Courses (Title, Description, Category, Difficulty, InstructorId, Status, ThumbnailUrl, LockReason)
SELECT v.Title, v.Description, v.Category, v.Difficulty, u.Id, v.Status, v.ThumbnailUrl, v.LockReason
FROM (VALUES
    (@tTS,   N'Master enterprise-grade TypeScript type gymnastics, React 18 concurrent rendering, custom hooks, and scalable state management.', N'Frontend Engineering', N'Intermediate', N'tutor', N'Published', N'~/Uploads/Covers/cover-typescript-react.jpg', CAST(NULL AS NVARCHAR(500))),
    (@tAlgo, N'Explore rigorous algorithmic principles, asymptotic complexity, graph theory, dynamic programming, and proof techniques.', N'Computer Science', N'Advanced', N'tutor', N'Published', N'~/Uploads/Covers/cover-algorithms-math.jpg', NULL),
    (@tPy,   N'Comprehensive introduction to Python programming syntax, idiomatic data structures, file I/O operations, and task automation.', N'Programming Fundamentals', N'Beginner', N'tutor', N'Published', N'~/Uploads/Covers/cover-python-essentials.jpg', NULL),
    (@tWeb,  N'Build your first web pages: the structure of an HTML document, styling with CSS and laying out content with Flexbox.', N'Web Development', N'Beginner', N'grace', N'Published', N'~/Uploads/Covers/cover-web-basics.jpg', NULL),
    (@tDS,   N'Learn how data is organised in Python: lists, tuples, dictionaries, stacks, queues and linked lists.', N'Computer Science', N'Intermediate', N'ada', N'Published', N'~/Uploads/Covers/cover-data-structures.jpg', NULL),
    (@tSQL,  N'Learn to read from a relational database: tables, SELECT, WHERE and JOINs, with plenty of examples.', N'Data & Databases', N'Beginner', N'grace', N'Published', N'~/Uploads/Covers/cover-sql-essentials.jpg', NULL),
    (@tJS,   N'A short, practical start to JavaScript: variables, functions and arrays, with a quiz and coding challenges.', N'Programming Fundamentals', N'Beginner', N'tutor', N'Pending Review', N'~/Uploads/Covers/cover-javascript-foundations.jpg', NULL),
    (@tGit,  N'Understand version control and make your first commit. Still being written.', N'Developer Tools', N'Beginner', N'ada', N'Draft', N'~/Uploads/Covers/cover-git-github.jpg', NULL),
    (@tPerl, N'An older course on Perl scripting for text processing.', N'Programming Fundamentals', N'Beginner', N'grace', N'Locked', N'~/Uploads/Covers/cover-perl-scripting.jpg', N'Content is out of date and is being rewritten.')
) v(Title, Description, Category, Difficulty, Instructor, Status, ThumbnailUrl, LockReason)
JOIN dbo.Users u ON u.Username = v.Instructor
WHERE NOT EXISTS (SELECT 1 FROM dbo.Courses c WHERE c.Title = v.Title);

-- =====================================
-- Attach cover images and avatars to rows that already existed from an earlier run
-- =====================================
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-typescript-react.jpg' WHERE Title = @tTS AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-algorithms-math.jpg' WHERE Title = @tAlgo AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-python-essentials.jpg' WHERE Title = @tPy AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-web-basics.jpg' WHERE Title = @tWeb AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-data-structures.jpg' WHERE Title = @tDS AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-sql-essentials.jpg' WHERE Title = @tSQL AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-javascript-foundations.jpg' WHERE Title = @tJS AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-git-github.jpg' WHERE Title = @tGit AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');
UPDATE dbo.Courses SET ThumbnailUrl = '~/Uploads/Covers/cover-perl-scripting.jpg' WHERE Title = @tPerl AND (ThumbnailUrl IS NULL OR ThumbnailUrl = '');

UPDATE dbo.Users SET AvatarUrl = '~/Uploads/Avatars/avatar-grace-hopper.jpg' WHERE Username = N'grace' AND (AvatarUrl IS NULL OR AvatarUrl = '');
UPDATE dbo.Users SET AvatarUrl = '~/Uploads/Avatars/avatar-ada-lovelace.jpg' WHERE Username = N'ada' AND (AvatarUrl IS NULL OR AvatarUrl = '');
UPDATE dbo.Users SET AvatarUrl = '~/Uploads/Avatars/avatar-alan-turing.jpg' WHERE Username = N'tutor' AND (AvatarUrl IS NULL OR AvatarUrl = '');
UPDATE dbo.Users SET AvatarUrl = '~/Uploads/Avatars/avatar-helena-zhang.jpg' WHERE Username = N'helena' AND (AvatarUrl IS NULL OR AvatarUrl = '');
UPDATE dbo.Users SET AvatarUrl = '~/Uploads/Avatars/avatar-marcus-vance.jpg' WHERE Username = N'marcus' AND (AvatarUrl IS NULL OR AvatarUrl = '');
UPDATE dbo.Users SET AvatarUrl = '~/Uploads/Avatars/avatar-sarah-connor.jpg' WHERE Username = N'learner' AND (AvatarUrl IS NULL OR AvatarUrl = '');
UPDATE dbo.Users SET AvatarUrl = '~/Uploads/Avatars/avatar-admin.jpg' WHERE Username = N'admin' AND (AvatarUrl IS NULL OR AvatarUrl = '');

-- =====================================
-- Lessons
-- =====================================
INSERT INTO dbo.Lessons (CourseId, Title, Content, CodeSnippet, CodeLanguage, OrderIndex, DurationMinutes)
SELECT c.Id, v.Title, v.Content, v.Code, v.Lang, v.OrderIndex, v.Minutes
FROM (VALUES
    -- TypeScript
    (@tTS, N'Introduction to TypeScript Types', N'Learn how type annotations make your web applications robust and bug-free.',
        N'const greeting: string = "Hello, CodeLab!";' + CHAR(10) + N'console.log(greeting);', N'typescript', 1, 15),
    (@tTS, N'Interfaces and Type Aliases', N'Interfaces describe the shape of an object. A type alias can also name a union such as "Active" or "Suspended".',
        N'interface Course {' + CHAR(10) + N'  title: string;' + CHAR(10) + N'  lessons: number;' + CHAR(10) + N'}' + CHAR(10) + N'const course: Course = { title: "TypeScript", lessons: 4 };' + CHAR(10) + N'console.log(course.title);', N'typescript', 2, 15),
    (@tTS, N'Generics in Practice', N'Generics let one function work with many types while keeping type safety. The type parameter goes in angle brackets.',
        N'function identity<T>(value: T): T {' + CHAR(10) + N'  return value;' + CHAR(10) + N'}' + CHAR(10) + N'console.log(identity<string>("CodeLab"));', N'typescript', 3, 20),
    (@tTS, N'Typing React Components', N'Props are typed with an interface, so the compiler warns you when a required prop is missing or has the wrong type.',
        N'interface ButtonProps {' + CHAR(10) + N'  label: string;' + CHAR(10) + N'  disabled?: boolean;' + CHAR(10) + N'}', N'typescript', 4, 20),
    -- Algorithms
    (@tAlgo, N'Big-O Notation Made Simple', N'Big-O describes how the running time of an algorithm grows with the size of its input. Constant, logarithmic, linear and quadratic growth are the ones to know first.',
        N'const items = [1, 2, 3, 4, 5];' + CHAR(10) + N'let steps = 0;' + CHAR(10) + N'for (const item of items) { steps++; }' + CHAR(10) + N'console.log(steps);', N'javascript', 1, 15),
    (@tAlgo, N'Sorting: Bubble to Merge', N'Bubble sort swaps neighbours until the list is ordered. Merge sort splits the list, sorts the halves and merges them, which is much faster on large inputs.',
        N'const numbers = [5, 2, 9, 1];' + CHAR(10) + N'numbers.sort((a, b) => a - b);' + CHAR(10) + N'console.log(numbers.join(", "));', N'javascript', 2, 25),
    (@tAlgo, N'Graphs and Breadth-First Search', N'A graph is a set of nodes joined by edges. Breadth-first search visits the nodes closest to the start first, using a queue.',
        N'const queue = ["A"];' + CHAR(10) + N'const visited = [];' + CHAR(10) + N'while (queue.length > 0) {' + CHAR(10) + N'  visited.push(queue.shift());' + CHAR(10) + N'}' + CHAR(10) + N'console.log(visited.length);', N'javascript', 3, 25),
    (@tAlgo, N'Dynamic Programming: Fibonacci', N'Dynamic programming stores the answers to small sub-problems so they are never computed twice. The Fibonacci numbers are the classic example.',
        N'const fib = [0, 1];' + CHAR(10) + N'for (let i = 2; i <= 10; i++) { fib[i] = fib[i - 1] + fib[i - 2]; }' + CHAR(10) + N'console.log(fib[10]);', N'javascript', 4, 30),
    -- Python Essentials
    (@tPy, N'Variables and Printing', N'A variable names a value. Use print() to show a value on the screen.',
        N'name = "CodeLab"' + CHAR(10) + N'print("Welcome to " + name)', N'python', 1, 10),
    (@tPy, N'Lists and Loops', N'A list holds an ordered collection. A for loop repeats a block of code for each item in it.',
        N'scores = [70, 85, 92]' + CHAR(10) + N'for score in scores:' + CHAR(10) + N'    print(score)', N'python', 2, 15),
    (@tPy, N'Functions and Files', N'Functions package reusable steps. Python can also open a text file and read or write lines.',
        N'def add(a, b):' + CHAR(10) + N'    return a + b' + CHAR(10) + N'print(add(2, 3))', N'python', 3, 20),
    (@tPy, N'Automating Boring Tasks', N'Put a loop, a function and a file together and a task that took ten minutes by hand takes one second.',
        N'files = ["a.txt", "b.txt", "c.txt"]' + CHAR(10) + N'for name in files:' + CHAR(10) + N'    print("Processing " + name)', N'python', 4, 20),
    -- Web Basics
    (@tWeb, N'Structure of an HTML Page', N'Every page has a head, with the title, and a body, with the content. Headings, paragraphs and links are the basic building blocks.',
        N'<h1>Hello, CodeLab</h1>' + CHAR(10) + N'<p>My first web page.</p>', N'html', 1, 10),
    (@tWeb, N'Styling with CSS', N'CSS rules pick elements with a selector and set properties such as colour and font size.',
        N'h1 {' + CHAR(10) + N'  color: rebeccapurple;' + CHAR(10) + N'  font-size: 2rem;' + CHAR(10) + N'}', N'css', 2, 15),
    (@tWeb, N'Layout with Flexbox', N'Flexbox arranges items in a row or column and can centre them horizontally and vertically.',
        N'.row {' + CHAR(10) + N'  display: flex;' + CHAR(10) + N'  justify-content: center;' + CHAR(10) + N'  align-items: center;' + CHAR(10) + N'}', N'css', 3, 15),
    -- Data Structures in Python
    (@tDS, N'Lists, Tuples and Dictionaries', N'Lists can change, tuples cannot, and dictionaries map keys to values.',
        N'point = (3, 4)' + CHAR(10) + N'ages = {"Alice": 21, "Ben": 23}' + CHAR(10) + N'print(ages["Alice"])', N'python', 1, 15),
    (@tDS, N'Stacks and Queues', N'A stack is last in, first out. A queue is first in, first out. A Python list can act as either.',
        N'stack = [1, 2, 3]' + CHAR(10) + N'stack.append(4)' + CHAR(10) + N'print(stack.pop())', N'python', 2, 20),
    (@tDS, N'Linked Lists', N'A linked list stores each item with a reference to the next one, which makes inserting in the middle cheap.',
        N'class Node:' + CHAR(10) + N'    def __init__(self, value):' + CHAR(10) + N'        self.value = value' + CHAR(10) + N'        self.next = None', N'python', 3, 25),
    -- SQL Essentials
    (@tSQL, N'Tables and Rows', N'A relational database stores data in tables. Each row is one record and each column is one field.',
        N'SELECT * FROM Users;', N'sql', 1, 10),
    (@tSQL, N'SELECT and WHERE', N'SELECT chooses the columns to return and WHERE keeps only the rows that match a condition.',
        N'SELECT Username, Role' + CHAR(10) + N'FROM Users' + CHAR(10) + N'WHERE Role = ''Learner'';', N'sql', 2, 15),
    (@tSQL, N'JOINs Explained', N'A JOIN combines rows from two tables that share a value, such as a course and its instructor.',
        N'SELECT c.Title, u.FullName' + CHAR(10) + N'FROM Courses c' + CHAR(10) + N'JOIN Users u ON u.Id = c.InstructorId;', N'sql', 3, 20),
    -- JavaScript Foundations (waiting for review)
    (@tJS, N'Variables and Data Types', N'Use const for values that never change and let for values that do. Strings, numbers and booleans are the basic types.',
        N'const course = "JavaScript";' + CHAR(10) + N'let lessons = 3;' + CHAR(10) + N'console.log(course + " has " + lessons + " lessons");', N'javascript', 1, 10),
    (@tJS, N'Writing Functions', N'A function packages reusable logic. It takes parameters and gives back a value with return.',
        N'function add(a, b) {' + CHAR(10) + N'  return a + b;' + CHAR(10) + N'}' + CHAR(10) + N'console.log(add(2, 3));', N'javascript', 2, 15),
    (@tJS, N'Working with Arrays', N'Arrays hold ordered lists and start counting at 0. The map method builds a new array by transforming each item.',
        N'const scores = [70, 85, 92];' + CHAR(10) + N'const doubled = scores.map(s => s * 2);' + CHAR(10) + N'console.log(doubled);', N'javascript', 3, 20),
    -- Git (draft) and Perl (locked)
    (@tGit, N'What is Version Control?', N'Version control records every change to your files, so you can go back and work with others without overwriting each other.', NULL, NULL, 1, 10),
    (@tGit, N'Your First Commit', N'A commit is a saved snapshot. Stage your changes with git add, then record them with git commit.',
        N'git add .' + CHAR(10) + N'git commit -m "My first commit"', N'bash', 2, 15),
    (@tPerl, N'Hello Perl', N'Perl is a scripting language that is strong at processing text.',
        N'print "Hello, CodeLab!\n";', N'perl', 1, 10)
) v(CourseTitle, Title, Content, Code, Lang, OrderIndex, Minutes)
JOIN dbo.Courses c ON c.Title = v.CourseTitle
WHERE NOT EXISTS (SELECT 1 FROM dbo.Lessons l WHERE l.CourseId = c.Id AND l.Title = v.Title);

-- =====================================
-- Quizzes
-- =====================================
INSERT INTO dbo.Quizzes (CourseId, Title, PassMark, CreatedByUserId, Instructions)
SELECT c.Id, v.Title, v.PassMark, u.Id, v.Instructions
FROM (VALUES
    (@tTS,   N'TypeScript Fundamentals Quiz', 80, N'tutor', N'Test your knowledge on static typing and basic interfaces.'),
    (@tAlgo, N'Algorithms and Big-O Quiz',   70, N'tutor', N'Three questions on complexity, sorting and graphs. You need 70% to pass.'),
    (@tPy,   N'Python Essentials Quiz',      70, N'tutor', N'Three questions on printing, lists and indentation. You need 70% to pass.'),
    (@tWeb,  N'HTML and CSS Quiz',           70, N'grace', N'Three questions on HTML tags, CSS properties and Flexbox. You need 70% to pass.'),
    (@tDS,   N'Python Data Structures Quiz', 70, N'ada',   N'Three questions on stacks, tuples and dictionaries. You need 70% to pass.'),
    (@tSQL,  N'SQL Essentials Quiz',         70, N'grace', N'Three questions on SELECT, WHERE and JOIN. You need 70% to pass.'),
    (@tJS,   N'JavaScript Foundations Quiz', 70, N'tutor', N'Four quick questions on variables, functions and arrays. You need 70% to pass.')
) v(CourseTitle, Title, PassMark, Creator, Instructions)
JOIN dbo.Courses c ON c.Title = v.CourseTitle
JOIN dbo.Users u ON u.Username = v.Creator
WHERE NOT EXISTS (SELECT 1 FROM dbo.Quizzes q WHERE q.Title = v.Title);

-- =====================================
-- Quiz questions
-- =====================================
INSERT INTO dbo.QuizQuestions (QuizId, QuestionText, QuestionType, OptionsJson, CorrectOptionIndex, Explanation, OrderIndex)
SELECT q.Id, v.QuestionText, v.QuestionType, v.OptionsJson, v.CorrectIndex, v.Explanation, v.OrderIndex
FROM (VALUES
    (N'TypeScript Fundamentals Quiz', 1, N'Which keyword is used to declare a block-scoped variable in modern JavaScript/TypeScript?', N'Multiple Choice',
        N'["var", "let", "global", "dim"]', 1, N'The "let" keyword defines block-scoped variables in modern ECMAScript.'),
    (N'TypeScript Fundamentals Quiz', 2, N'What does the any type do in TypeScript?', N'Multiple Choice',
        N'["Turns off type checking for that value","Creates a number","Makes a value read-only","Declares a class"]', 0, N'any opts out of type checking, so use it sparingly.'),
    (N'TypeScript Fundamentals Quiz', 3, N'An interface can describe the shape of an object.', N'True-False',
        N'["True","False"]', 0, N'Interfaces list the properties an object must have.'),
    (N'TypeScript Fundamentals Quiz', 4, N'Which syntax declares a generic function?', N'Multiple Choice',
        N'["function id<T>(x: T): T","function id(x: generic): any","function<T> id(x)","generic function id(x)"]', 0, N'Type parameters go in angle brackets after the function name.'),

    (N'Algorithms and Big-O Quiz', 1, N'What is the time complexity of binary search on a sorted array?', N'Multiple Choice',
        N'["O(n)","O(log n)","O(n squared)","O(1)"]', 1, N'Each step halves the range that is left to search.'),
    (N'Algorithms and Big-O Quiz', 2, N'Which sorting algorithm repeatedly swaps adjacent items that are out of order?', N'Multiple Choice',
        N'["Merge sort","Quick sort","Bubble sort","Heap sort"]', 2, N'Bubble sort moves the largest items to the end one swap at a time.'),
    (N'Algorithms and Big-O Quiz', 3, N'Breadth-first search explores neighbours level by level.', N'True-False',
        N'["True","False"]', 0, N'BFS uses a queue to visit the nodes in layers.'),

    (N'Python Essentials Quiz', 1, N'Which function prints text to the screen in Python?', N'Multiple Choice',
        N'["echo()","print()","write()","console()"]', 1, N'print() writes its arguments to the screen.'),
    (N'Python Essentials Quiz', 2, N'What does len([1, 2, 3]) return?', N'Multiple Choice',
        N'["2","3","4","An error"]', 1, N'len() counts the items in the list.'),
    (N'Python Essentials Quiz', 3, N'Python uses indentation to group statements.', N'True-False',
        N'["True","False"]', 0, N'Indentation defines blocks such as loop and function bodies.'),

    (N'HTML and CSS Quiz', 1, N'Which tag defines the largest heading?', N'Multiple Choice',
        N'["<h6>","<head>","<h1>","<header>"]', 2, N'h1 is the top-level heading.'),
    (N'HTML and CSS Quiz', 2, N'Which CSS property changes the text colour?', N'Multiple Choice',
        N'["font-color","text-style","color","foreground"]', 2, N'The color property sets the text colour.'),
    (N'HTML and CSS Quiz', 3, N'Flexbox can centre items both horizontally and vertically.', N'True-False',
        N'["True","False"]', 0, N'justify-content and align-items control the two directions.'),

    (N'Python Data Structures Quiz', 1, N'Which structure follows last-in, first-out order?', N'Multiple Choice',
        N'["Queue","Stack","Set","Tuple"]', 1, N'A stack removes the item that was added most recently.'),
    (N'Python Data Structures Quiz', 2, N'Which Python type cannot be changed after it is created?', N'Multiple Choice',
        N'["list","dict","tuple","set"]', 2, N'Tuples are immutable.'),
    (N'Python Data Structures Quiz', 3, N'A dictionary stores key-value pairs.', N'True-False',
        N'["True","False"]', 0, N'Each key maps to one value.'),

    (N'SQL Essentials Quiz', 1, N'Which statement reads rows from a table?', N'Multiple Choice',
        N'["GET","SELECT","FETCH TABLE","OPEN"]', 1, N'SELECT returns rows from one or more tables.'),
    (N'SQL Essentials Quiz', 2, N'Which clause filters rows?', N'Multiple Choice',
        N'["WHERE","ORDER BY","GROUP","INTO"]', 0, N'WHERE keeps only the rows that match the condition.'),
    (N'SQL Essentials Quiz', 3, N'A JOIN combines rows from two tables.', N'True-False',
        N'["True","False"]', 0, N'A JOIN matches rows on a shared value.'),

    (N'JavaScript Foundations Quiz', 1, N'Which keyword declares a variable that cannot be reassigned?', N'Multiple Choice',
        N'["var","let","const","static"]', 2, N'const creates a binding that cannot be reassigned.'),
    (N'JavaScript Foundations Quiz', 2, N'What does a function return when it has no return statement?', N'Multiple Choice',
        N'["0","null","undefined","An empty string"]', 2, N'Without a return statement a function gives back undefined.'),
    (N'JavaScript Foundations Quiz', 3, N'JavaScript arrays are zero-indexed.', N'True-False',
        N'["True","False"]', 0, N'The first item of an array is at index 0.'),
    (N'JavaScript Foundations Quiz', 4, N'Which array method creates a new array by transforming every element?', N'Multiple Choice',
        N'["filter","map","push","forEach"]', 1, N'map returns a new array with the result of the callback for each item.')
) v(QuizTitle, OrderIndex, QuestionText, QuestionType, OptionsJson, CorrectIndex, Explanation)
JOIN dbo.Quizzes q ON q.Title = v.QuizTitle
WHERE NOT EXISTS (SELECT 1 FROM dbo.QuizQuestions x WHERE x.QuizId = q.Id AND x.OrderIndex = v.OrderIndex);

-- =====================================
-- Coding challenges: ONE per course, the same rule the Tutor pages enforce (ChallengeManager)
-- =====================================

-- Older versions of this script added 2 or 3 challenges to some courses. Keep each course's
-- first challenge and remove the rest; their code submissions are removed with them (ON DELETE CASCADE).
DELETE ch
FROM dbo.CodingChallenges ch
WHERE EXISTS (SELECT 1 FROM dbo.CodingChallenges earlier
              WHERE earlier.CourseId = ch.CourseId AND earlier.Id < ch.Id);

INSERT INTO dbo.CodingChallenges (CourseId, Title, Description, Difficulty, Language, StarterCode, ExpectedOutput, PointsReward)
SELECT c.Id, v.Title, v.Description, v.Difficulty, v.Lang, v.StarterCode, v.ExpectedOutput, v.Points
FROM (VALUES
    (@tTS,   N'Say Hello',        N'Print exactly: Hello, CodeLab!', N'Beginner', N'javascript',
        N'// Print the greeting below' + CHAR(10), N'Hello, CodeLab!', 50),
    (@tAlgo, N'Factorial of Five', N'Print the factorial of 5 (5 x 4 x 3 x 2 x 1).', N'Intermediate', N'javascript',
        N'function factorial(n) {' + CHAR(10) + N'  // your code here' + CHAR(10) + N'}' + CHAR(10) + N'console.log(factorial(5));', N'120', 100),
    (@tPy,   N'Hello Python',     N'Print exactly: Hello, CodeLab!', N'Beginner', N'python',
        N'# Print the greeting below' + CHAR(10), N'Hello, CodeLab!', 50),
    (@tDS,   N'Stack Pop',        N'Push 4 onto the stack, pop twice, and print the sum of the two popped values.', N'Beginner', N'python',
        N'stack = [1, 2, 3]' + CHAR(10) + N'# Push 4, then pop twice and print the sum' + CHAR(10), N'7', 75),
    (@tJS,   N'Say Hello',        N'Print exactly: Hello, CodeLab!', N'Beginner', N'javascript',
        N'// Print the greeting below' + CHAR(10), N'Hello, CodeLab!', 50)
) v(CourseTitle, Title, Description, Difficulty, Lang, StarterCode, ExpectedOutput, Points)
JOIN dbo.Courses c ON c.Title = v.CourseTitle
-- Skip any course that already has a challenge, so re-running never adds a second one
WHERE NOT EXISTS (SELECT 1 FROM dbo.CodingChallenges x WHERE x.CourseId = c.Id);

-- =====================================
-- Learner progress: enrolments and completed lessons.
-- LessonsDone is how many lessons, counted from lesson 1, the learner has finished.
-- =====================================
DECLARE @Progress TABLE (Username NVARCHAR(50), CourseTitle NVARCHAR(200), LessonsDone INT, DaysAgo INT);
INSERT INTO @Progress (Username, CourseTitle, LessonsDone, DaysAgo) VALUES
    (N'learner',  @tTS,   2, 20), (N'learner',  @tPy,   4, 18), (N'learner',  @tWeb,  1, 6),
    (N'alice',    @tTS,   4, 30), (N'alice',    @tAlgo, 3, 14), (N'alice',    @tSQL,  2, 8),
    (N'ben',      @tPy,   4, 28), (N'ben',      @tWeb,  3, 16), (N'ben',      @tDS,   1, 5),
    (N'chloe',    @tAlgo, 1, 12), (N'chloe',    @tPy,   2, 10), (N'chloe',    @tSQL,  3, 15),
    (N'daniel',   @tTS,   1, 9),  (N'daniel',   @tWeb,  2, 7),
    (N'emma',     @tPy,   3, 22), (N'emma',     @tDS,   2, 11), (N'emma',     @tTS,   4, 25),
    (N'farid',    @tAlgo, 2, 13), (N'farid',    @tSQL,  1, 4),
    (N'gracelee', @tWeb,  3, 24), (N'gracelee', @tDS,   3, 19), (N'gracelee', @tPy,   1, 6),
    (N'hiro',     @tTS,   3, 17), (N'hiro',     @tPy,   4, 21),
    (N'ivan',     @tPy,   1, 15);

INSERT INTO dbo.CourseEnrollments (LearnerId, CourseId, EnrolledAt, ProgressPercent, IsCompleted, CompletedAt)
SELECT u.Id, c.Id, DATEADD(DAY, -p.DaysAgo, SYSUTCDATETIME()),
       CAST(CASE WHEN t.Total = 0 THEN 0
                 WHEN p.LessonsDone >= t.Total THEN 100
                 ELSE 100.0 * p.LessonsDone / t.Total END AS DECIMAL(5, 2)),
       CASE WHEN t.Total > 0 AND p.LessonsDone >= t.Total THEN 1 ELSE 0 END,
       CASE WHEN t.Total > 0 AND p.LessonsDone >= t.Total
            THEN DATEADD(HOUR, 3 * t.Total, DATEADD(DAY, -p.DaysAgo, SYSUTCDATETIME())) END
FROM @Progress p
JOIN dbo.Users u ON u.Username = p.Username
JOIN dbo.Courses c ON c.Title = p.CourseTitle
CROSS APPLY (SELECT COUNT(*) AS Total FROM dbo.Lessons l WHERE l.CourseId = c.Id) t
WHERE NOT EXISTS (SELECT 1 FROM dbo.CourseEnrollments e WHERE e.LearnerId = u.Id AND e.CourseId = c.Id);

INSERT INTO dbo.LessonCompletions (LearnerId, LessonId, CompletedAt)
SELECT u.Id, l.Id, DATEADD(HOUR, 3 * l.OrderIndex, DATEADD(DAY, -p.DaysAgo, SYSUTCDATETIME()))
FROM @Progress p
JOIN dbo.Users u ON u.Username = p.Username
JOIN dbo.Courses c ON c.Title = p.CourseTitle
JOIN dbo.Lessons l ON l.CourseId = c.Id AND l.OrderIndex <= p.LessonsDone
WHERE NOT EXISTS (SELECT 1 FROM dbo.LessonCompletions x WHERE x.LearnerId = u.Id AND x.LessonId = l.Id);

-- =====================================
-- Quiz attempts (one per learner and quiz; Passed follows the quiz's pass mark)
-- =====================================
INSERT INTO dbo.QuizAttempts (LearnerId, QuizId, ScorePercent, Passed, TotalQuestions, CorrectCount, AttemptedAt)
SELECT u.Id, q.Id, v.Score, CASE WHEN v.Score >= q.PassMark THEN 1 ELSE 0 END, v.Total, v.Correct, DATEADD(DAY, -v.DaysAgo, SYSUTCDATETIME())
FROM (VALUES
    (N'learner',  N'Python Essentials Quiz',      100, 3, 3, 17),
    (N'learner',  N'TypeScript Fundamentals Quiz', 50, 4, 2, 15),
    (N'alice',    N'TypeScript Fundamentals Quiz', 100, 4, 4, 28),
    (N'alice',    N'Algorithms and Big-O Quiz',    66, 3, 2, 12),
    (N'alice',    N'SQL Essentials Quiz',         100, 3, 3, 6),
    (N'ben',      N'Python Essentials Quiz',      100, 3, 3, 26),
    (N'ben',      N'HTML and CSS Quiz',           100, 3, 3, 14),
    (N'chloe',    N'SQL Essentials Quiz',         100, 3, 3, 13),
    (N'daniel',   N'HTML and CSS Quiz',            66, 3, 2, 6),
    (N'emma',     N'Python Essentials Quiz',       66, 3, 2, 20),
    (N'emma',     N'TypeScript Fundamentals Quiz', 100, 4, 4, 23),
    (N'gracelee', N'HTML and CSS Quiz',           100, 3, 3, 22),
    (N'gracelee', N'Python Data Structures Quiz', 100, 3, 3, 17),
    (N'hiro',     N'Python Essentials Quiz',      100, 3, 3, 19),
    (N'hiro',     N'TypeScript Fundamentals Quiz',  75, 4, 3, 15)
) v(Username, QuizTitle, Score, Total, Correct, DaysAgo)
JOIN dbo.Users u ON u.Username = v.Username
JOIN dbo.Quizzes q ON q.Title = v.QuizTitle
WHERE NOT EXISTS (SELECT 1 FROM dbo.QuizAttempts a WHERE a.LearnerId = u.Id AND a.QuizId = q.Id);

-- =====================================
-- Code submissions
-- =====================================
INSERT INTO dbo.CodeSubmissions (LearnerId, ChallengeId, SubmittedCode, Status, OutputResult, SubmittedAt, AiFeedback)
SELECT u.Id, ch.Id, v.Code, v.Status, v.OutputText, DATEADD(DAY, -v.DaysAgo, SYSUTCDATETIME()), v.Feedback
FROM (VALUES
    -- learner and ben get one wrong attempt before their pass, so the results show Failed and Error too
    (N'learner',  @tPy,   N'Hello Python',     N'print("Hello CodeLab")', N'Failed', N'Hello CodeLab', 17,
        CAST(N'Close. The expected output has a comma and an exclamation mark: Hello, CodeLab!' AS NVARCHAR(MAX))),
    (N'learner',  @tPy,   N'Hello Python',     N'print("Hello, CodeLab!")', N'Passed', N'Hello, CodeLab!', 16, NULL),
    (N'alice',    @tTS,   N'Say Hello',        N'console.log("Hello, CodeLab!");', N'Passed', N'Hello, CodeLab!', 27, NULL),
    (N'ben',      @tPy,   N'Hello Python',     N'print(Hello, CodeLab!)', N'Error', N'SyntaxError: invalid syntax', 26,
        N'Text must be inside quotes. Write print("Hello, CodeLab!").'),
    (N'ben',      @tPy,   N'Hello Python',     N'print("Hello, CodeLab!")', N'Passed', N'Hello, CodeLab!', 25, NULL),
    (N'emma',     @tPy,   N'Hello Python',     N'print("Hello, CodeLab!")', N'Passed', N'Hello, CodeLab!', 19, NULL),
    (N'hiro',     @tPy,   N'Hello Python',     N'print("Hello, CodeLab!")', N'Passed', N'Hello, CodeLab!', 18, NULL),
    (N'chloe',    @tAlgo, N'Factorial of Five', N'function factorial(n) { return n * factorial(n - 1); }' + CHAR(10) + N'console.log(factorial(5));', N'Failed', N'RangeError: Maximum call stack size exceeded', 9,
        N'The recursion never stops. Return 1 when n is 1 or less.'),
    (N'gracelee', @tDS,   N'Stack Pop',        N'stack = [1, 2, 3]' + CHAR(10) + N'stack.append(4)' + CHAR(10) + N'print(stack.pop() + stack.pop())', N'Passed', N'7', 15, NULL),
    (N'daniel',   @tTS,   N'Say Hello',        N'console.log("Hello CodeLab");', N'Failed', N'Hello CodeLab', 8,
        N'Close. The expected output has a comma and an exclamation mark: Hello, CodeLab!')
) v(Username, CourseTitle, ChallengeTitle, Code, Status, OutputText, DaysAgo, Feedback)
JOIN dbo.Users u ON u.Username = v.Username
JOIN dbo.Courses c ON c.Title = v.CourseTitle
JOIN dbo.CodingChallenges ch ON ch.CourseId = c.Id AND ch.Title = v.ChallengeTitle
-- A learner can have several attempts at one challenge; skip only the exact same attempt (same code)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CodeSubmissions s
                  WHERE s.LearnerId = u.Id AND s.ChallengeId = ch.Id AND s.SubmittedCode = v.Code);

-- =====================================
-- Learner stats for the leaderboard (level and title follow LearnerManager.Levels)
-- =====================================
INSERT INTO dbo.LearnerStats (LearnerId, AchievementPoints, CurrentLevel, LevelTitle, NextMilestonePoints, StreakDays, LastActiveDate)
SELECT u.Id, v.Points, v.Level, v.Title, v.NextXp, v.Streak, CAST(DATEADD(HOUR, 8, SYSUTCDATETIME()) AS DATE)
FROM (VALUES
    (N'learner',  1250, 4, N'Code Voyager',      2000, 5),
    (N'alice',    3800, 6, N'Code Specialist',   5000, 12),
    (N'ben',      2650, 5, N'Skilled Developer', 3500, 8),
    (N'chloe',    1500, 4, N'Code Voyager',      2000, 4),
    (N'daniel',    450, 1, N'Novice Coder',       500, 2),
    (N'emma',     2100, 5, N'Skilled Developer', 3500, 6),
    (N'farid',     700, 2, N'Code Explorer',     1000, 1),
    (N'gracelee', 5200, 7, N'Expert Developer',  7500, 21),
    (N'hiro',     1900, 4, N'Code Voyager',      2000, 3),
    (N'ivan',      300, 1, N'Novice Coder',       500, 0)
) v(Username, Points, Level, Title, NextXp, Streak)
JOIN dbo.Users u ON u.Username = v.Username
WHERE NOT EXISTS (SELECT 1 FROM dbo.LearnerStats s WHERE s.LearnerId = u.Id);

-- =====================================
-- Discussions: general boards (no course) and course boards
-- =====================================
INSERT INTO dbo.DiscussionPosts (CourseId, AuthorId, Title, Content, CreatedAt)
SELECT c.Id, u.Id, v.Title, v.Content, DATEADD(DAY, -v.DaysAgo, SYSUTCDATETIME())
FROM (VALUES
    (CAST(NULL AS NVARCHAR(200)), N'alice', N'Welcome to CodeLab - introduce yourself here',
        N'Hi everyone! I am Alice and I am learning TypeScript. Tell us what you are learning and what you want to build.', 25),
    (NULL, N'emma', N'How do you stay consistent with daily practice?',
        N'I keep losing my streak after a busy day. What routines work for you?', 14),
    (NULL, N'ben', N'Which editor do you use for Python?',
        N'I have been using a plain text editor. Is it worth switching to a full IDE?', 9),
    (@tTS, N'daniel', N'When should I use an interface instead of a type alias?',
        N'Both seem to describe object shapes. Is there a rule of thumb?', 8),
    (@tPy, N'learner', N'My loop prints the list twice, what is wrong?',
        N'I wrote a for loop and then called print on the list again inside it. How do I print each item once?', 12),
    (@tAlgo, N'farid', N'Why is binary search O(log n)?',
        N'I understand it halves the list, but I do not see where log comes from.', 7),
    (@tSQL, N'chloe', N'INNER JOIN vs LEFT JOIN, quick explanation please',
        N'When do I need a LEFT JOIN? An INNER JOIN seems to give me what I want.', 5)
) v(CourseTitle, Author, Title, Content, DaysAgo)
JOIN dbo.Users u ON u.Username = v.Author
LEFT JOIN dbo.Courses c ON c.Title = v.CourseTitle
WHERE NOT EXISTS (SELECT 1 FROM dbo.DiscussionPosts p WHERE p.Title = v.Title);

INSERT INTO dbo.DiscussionReplies (PostId, AuthorId, Content, CreatedAt)
SELECT p.Id, u.Id, v.Content, DATEADD(HOUR, v.HoursAfter, p.CreatedAt)
FROM (VALUES
    (N'Welcome to CodeLab - introduce yourself here', N'ben',   N'Welcome Alice! I am working through the Python courses. Happy to help if you get stuck.', 5),
    (N'Welcome to CodeLab - introduce yourself here', N'tutor', N'Great to see everyone here. Ask questions in the course boards and we will answer them.', 20),
    (N'How do you stay consistent with daily practice?', N'hiro',  N'Ten minutes a day, always at the same time. Even one small lesson keeps the streak alive.', 6),
    (N'How do you stay consistent with daily practice?', N'grace', N'Pick a tiny goal, such as one lesson or one challenge, so a busy day never breaks the habit.', 30),
    (N'Which editor do you use for Python?', N'chloe', N'An IDE helps a lot once your programs get bigger. Autocomplete saves time.', 10),
    (N'Which editor do you use for Python?', N'ada',   N'Start with whatever lets you run code quickly. You can switch later without losing anything.', 26),
    (N'When should I use an interface instead of a type alias?', N'tutor', N'Use an interface for object shapes you may extend later, and a type alias for unions and other combinations.', 12),
    (N'When should I use an interface instead of a type alias?', N'alice', N'I follow the same rule. Interfaces for objects, aliases for unions.', 18),
    (N'My loop prints the list twice, what is wrong?', N'tutor', N'Remove the extra print(scores) inside the loop. Printing the loop variable is enough.', 8),
    (N'My loop prints the list twice, what is wrong?', N'ben',   N'Check your indentation too. A print outside the loop runs only once.', 14),
    (N'Why is binary search O(log n)?', N'tutor', N'If you halve 1000 items you reach 1 after about 10 steps. That number of halvings is the logarithm.', 10),
    (N'INNER JOIN vs LEFT JOIN, quick explanation please', N'grace', N'INNER JOIN keeps only rows with a match on both sides. LEFT JOIN also keeps unmatched rows from the left table.', 7)
) v(PostTitle, Author, Content, HoursAfter)
JOIN dbo.DiscussionPosts p ON p.Title = v.PostTitle
JOIN dbo.Users u ON u.Username = v.Author
WHERE NOT EXISTS (SELECT 1 FROM dbo.DiscussionReplies r WHERE r.PostId = p.Id AND r.AuthorId = u.Id AND r.Content = v.Content);

-- =====================================
-- Audit log history (skipped if it was added before)
-- =====================================
IF NOT EXISTS (SELECT 1 FROM dbo.AuditLogs a JOIN dbo.Users u ON u.Id = a.UserId
               WHERE u.Username = N'ivan' AND a.Action = N'SUSPEND_USER')
BEGIN
    INSERT INTO dbo.AuditLogs (UserId, Action, Details, Timestamp)
    SELECT u.Id, v.Action, v.Details, DATEADD(MINUTE, -v.MinutesAgo, SYSUTCDATETIME())
    FROM (VALUES
        (N'admin',    N'LOGIN',          N'Signed in.', 3000),
        (N'admin',    N'CREATE_USER',    N'Created the Tutor account ''grace''.', 2900),
        (N'admin',    N'CREATE_USER',    N'Created the Tutor account ''ada''.', 2880),
        (N'grace',    N'LOGIN',          N'Signed in.', 2800),
        (N'grace',    N'CREATE_COURSE',  N'Created the course ''Web Basics: HTML and CSS''.', 2790),
        (N'grace',    N'CREATE_LESSON',  N'Added the lesson ''Structure of an HTML Page''.', 2780),
        (N'grace',    N'CREATE_QUIZ',    N'Created the quiz ''HTML and CSS Quiz''.', 2770),
        (N'grace',    N'SUBMIT_COURSE',  N'Submitted ''Web Basics: HTML and CSS'' for review.', 2760),
        (N'ada',      N'LOGIN',          N'Signed in.', 2700),
        (N'ada',      N'CREATE_COURSE',  N'Created the course ''Data Structures in Python''.', 2690),
        (N'ada',      N'SUBMIT_COURSE',  N'Submitted ''Data Structures in Python'' for review.', 2680),
        (N'admin',    N'LOGIN',          N'Signed in.', 2600),
        (N'admin',    N'APPROVE_COURSE', N'Approved the course ''Web Basics: HTML and CSS''.', 2590),
        (N'admin',    N'APPROVE_COURSE', N'Approved the course ''Data Structures in Python''.', 2580),
        (N'admin',    N'LOCK_COURSE',    N'Locked the course ''Perl Scripting Basics'': Content is out of date and is being rewritten.', 2400),
        (N'alice',    N'REGISTER',       N'Registered a Learner account.', 86400),
        (N'ben',      N'REGISTER',       N'Registered a Learner account.', 79200),
        (N'chloe',    N'REGISTER',       N'Registered a Learner account.', 72000),
        (N'alice',    N'LOGIN',          N'Signed in.', 1500),
        (N'alice',    N'CREATE_DISCUSSION_POST', N'Started the discussion ''Welcome to CodeLab - introduce yourself here''.', 1490),
        (N'ben',      N'LOGIN',          N'Signed in.', 1300),
        (N'chloe',    N'LOGIN',          N'Signed in.', 1100),
        (N'learner',  N'LOGIN_FAILED',   N'Wrong password.', 900),
        (N'learner',  N'LOGIN',          N'Signed in.', 880),
        (N'emma',     N'LOGIN',          N'Signed in.', 700),
        (N'hiro',     N'LOGIN',          N'Signed in.', 600),
        (N'tutor',    N'LOGIN',          N'Signed in.', 500),
        (N'tutor',    N'CREATE_COURSE',  N'Created the course ''JavaScript Foundations: Functions and Arrays''.', 490),
        (N'tutor',    N'SUBMIT_COURSE',  N'Submitted ''JavaScript Foundations: Functions and Arrays'' for review.', 480),
        (N'ivan',     N'LOGIN_FAILED',   N'Wrong password.', 400),
        (N'admin',    N'SUSPEND_USER',   N'Suspended ''ivan''.', 300),
        (N'admin',    N'LOGOUT',         N'Signed out.', 200)
    ) v(Username, Action, Details, MinutesAgo)
    JOIN dbo.Users u ON u.Username = v.Username;
END;

-- =====================================
-- Badge catalog only. Awards are recorded on first eligibility check, in UTC.
-- =====================================
DECLARE @Catalog TABLE(Code varchar(50),Name nvarchar(100),Description nvarchar(300),Icon varchar(30),Category varchar(20),Metric varchar(20),Target int,SortOrder int);
INSERT @Catalog VALUES
 ('first-steps',N'First Steps',N'Complete your first lesson.','book','curriculum','lessons',1,1),
 ('dedicated-learner',N'Dedicated Learner',N'Complete 15 lessons.','book','curriculum','lessons',15,2),
 ('quiz-explorer',N'Quiz Explorer',N'Pass your first quiz.','award','quiz','quizzes',1,3),
 ('quiz-scholar',N'Quiz Scholar',N'Pass 10 different quizzes.','award','quiz','quizzes',10,4),
 ('problem-solver',N'Problem Solver',N'Pass your first coding challenge.','terminal','coding','challenges',1,5),
 ('code-explorer',N'Code Explorer',N'Pass 10 different coding challenges.','terminal','coding','challenges',10,6),
 ('rising-star',N'Rising Star',N'Reach 500 XP.','sparkles','xp','points',500,7),
 ('xp-champion',N'XP Champion',N'Reach 3,000 XP.','trophy','xp','points',3000,8),
 ('curriculum-expert',N'Curriculum Expert',N'Complete 25 lessons.','book','curriculum','lessons',25,9),
 ('curriculum-master',N'Curriculum Master',N'Complete 50 lessons.','trophy','curriculum','lessons',50,10),
 ('quiz-expert',N'Quiz Expert',N'Pass 20 different quizzes.','award','quiz','quizzes',20,11),
 ('quiz-master',N'Quiz Master',N'Pass 30 different quizzes.','trophy','quiz','quizzes',30,12),
 ('code-specialist',N'Code Specialist',N'Pass 25 different coding challenges.','terminal','coding','challenges',25,13),
 ('code-master',N'Code Master',N'Pass 50 different coding challenges.','trophy','coding','challenges',50,14),
 ('xp-elite',N'XP Elite',N'Reach 5,000 XP.','zap','xp','points',5000,15),
 ('xp-legend',N'XP Legend',N'Reach 10,000 XP.','flame','xp','points',10000,16),
 ('lesson-veteran',N'Lesson Veteran',N'Complete 75 lessons.','book','curriculum','lessons',75,17),
 ('knowledge-keeper',N'Knowledge Keeper',N'Complete 100 lessons.','award','curriculum','lessons',100,18),
 ('learning-legend',N'Learning Legend',N'Complete 150 lessons.','trophy','curriculum','lessons',150,19),
 ('quiz-veteran',N'Quiz Veteran',N'Pass 40 different quizzes.','award','quiz','quizzes',40,20),
 ('quiz-champion',N'Quiz Champion',N'Pass 50 different quizzes.','zap','quiz','quizzes',50,21),
 ('quiz-legend',N'Quiz Legend',N'Pass 75 different quizzes.','trophy','quiz','quizzes',75,22),
 ('code-veteran',N'Code Veteran',N'Pass 75 different coding challenges.','terminal','coding','challenges',75,23),
 ('code-champion',N'Code Champion',N'Pass 100 different coding challenges.','zap','coding','challenges',100,24),
 ('code-legend',N'Code Legend',N'Pass 150 different coding challenges.','trophy','coding','challenges',150,25),
 ('xp-vanguard',N'XP Vanguard',N'Reach 15,000 XP.','sparkles','xp','points',15000,26),
 ('xp-titan',N'XP Titan',N'Reach 25,000 XP.','flame','xp','points',25000,27),
 ('xp-immortal',N'XP Immortal',N'Reach 50,000 XP.','trophy','xp','points',50000,28)
;
-- Existing awards and their original dates are retained when requirements change.
UPDATE b SET Name=v.Name,Description=v.Description,Icon=v.Icon,Category=v.Category,Metric=v.Metric,Target=v.Target,SortOrder=v.SortOrder FROM dbo.Badges b JOIN @Catalog v ON b.Code=v.Code;
INSERT dbo.Badges(Code,Name,Description,Icon,Category,Metric,Target,SortOrder)
SELECT v.* FROM @Catalog v WHERE NOT EXISTS(SELECT 1 FROM dbo.Badges b WHERE b.Code=v.Code);

-- =====================================
-- What the database holds now
-- =====================================
SELECT 'Users' AS TableName, COUNT(*) AS Total FROM dbo.Users
UNION ALL SELECT 'Courses', COUNT(*) FROM dbo.Courses
UNION ALL SELECT 'Lessons', COUNT(*) FROM dbo.Lessons
UNION ALL SELECT 'Quizzes', COUNT(*) FROM dbo.Quizzes
UNION ALL SELECT 'QuizQuestions', COUNT(*) FROM dbo.QuizQuestions
UNION ALL SELECT 'CodingChallenges', COUNT(*) FROM dbo.CodingChallenges
UNION ALL SELECT 'CourseEnrollments', COUNT(*) FROM dbo.CourseEnrollments
UNION ALL SELECT 'LessonCompletions', COUNT(*) FROM dbo.LessonCompletions
UNION ALL SELECT 'QuizAttempts', COUNT(*) FROM dbo.QuizAttempts
UNION ALL SELECT 'CodeSubmissions', COUNT(*) FROM dbo.CodeSubmissions
UNION ALL SELECT 'LearnerStats', COUNT(*) FROM dbo.LearnerStats
UNION ALL SELECT 'DiscussionPosts', COUNT(*) FROM dbo.DiscussionPosts
UNION ALL SELECT 'DiscussionReplies', COUNT(*) FROM dbo.DiscussionReplies
UNION ALL SELECT 'AuditLogs', COUNT(*) FROM dbo.AuditLogs
UNION ALL SELECT 'Badges', COUNT(*) FROM dbo.Badges;

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
