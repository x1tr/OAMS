-- =====================================================
-- SmartOA 数据库初始化脚本
-- MySQL 8.0+
-- 10张表：t_employee, t_department, t_user, t_role,
--          t_user_role, t_permission, t_role_permission,
--          t_approval, t_announcement, t_audit_log
-- =====================================================

CREATE DATABASE IF NOT EXISTS smart_oa
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE smart_oa;

-- =====================================================
-- 1. 部门表（emp-svc）
-- =====================================================
DROP TABLE IF EXISTS t_department;
CREATE TABLE t_department (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    parent_id   BIGINT       DEFAULT 0   COMMENT '父部门ID，0=顶级',
    dept_name   VARCHAR(64)  NOT NULL    COMMENT '部门名称',
    dept_code   VARCHAR(32)  NOT NULL    COMMENT '部门编码',
    sort_order  INT          DEFAULT 0   COMMENT '排序',
    status      TINYINT      DEFAULT 1   COMMENT '0=禁用 1=启用',
    create_time DATETIME     DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_dept_code (dept_code)
) COMMENT '部门表';

-- =====================================================
-- 2. 员工表（emp-svc）
-- =====================================================
DROP TABLE IF EXISTS t_employee;
CREATE TABLE t_employee (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    emp_no      VARCHAR(32)  NOT NULL    COMMENT '工号',
    name        VARCHAR(64)  NOT NULL    COMMENT '姓名',
    gender      TINYINT      DEFAULT 0   COMMENT '0=未知 1=男 2=女',
    dept_id     BIGINT                   COMMENT '部门ID',
    dept_name   VARCHAR(64)              COMMENT '部门名称(冗余)',
    position    VARCHAR(64)              COMMENT '职位',
    phone       VARCHAR(20)              COMMENT '手机号',
    email       VARCHAR(128)             COMMENT '邮箱',
    id_card     VARCHAR(18)              COMMENT '身份证号',
    status      TINYINT      DEFAULT 1   COMMENT '0=离职 1=在职',
    create_time DATETIME     DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_emp_no (emp_no),
    INDEX idx_name (name),
    INDEX idx_dept (dept_id),
    INDEX idx_status (status)
) COMMENT '员工表';

-- =====================================================
-- 3. 用户表（admin-svc）
-- =====================================================
DROP TABLE IF EXISTS t_user;
CREATE TABLE t_user (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    username    VARCHAR(64)  NOT NULL    COMMENT '用户名',
    password    VARCHAR(255) NOT NULL    COMMENT '密码(BCrypt加密)',
    real_name   VARCHAR(64)              COMMENT '真实姓名',
    emp_id      BIGINT                   COMMENT '关联员工ID',
    phone       VARCHAR(20)              COMMENT '手机号',
    email       VARCHAR(128)             COMMENT '邮箱',
    status      TINYINT      DEFAULT 1   COMMENT '0=禁用 1=启用',
    create_time DATETIME     DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_username (username)
) COMMENT '用户表';

-- =====================================================
-- 4. 角色表（admin-svc）
-- =====================================================
DROP TABLE IF EXISTS t_role;
CREATE TABLE t_role (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_name   VARCHAR(64)  NOT NULL    COMMENT '角色名称',
    role_code   VARCHAR(64)  NOT NULL    COMMENT '角色编码 ADMIN/MANAGER/EMPLOYEE',
    description VARCHAR(255)             COMMENT '角色描述',
    status      TINYINT      DEFAULT 1   COMMENT '0=禁用 1=启用',
    create_time DATETIME     DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_role_code (role_code)
) COMMENT '角色表';

-- =====================================================
-- 5. 用户-角色关联表（admin-svc）
-- =====================================================
DROP TABLE IF EXISTS t_user_role;
CREATE TABLE t_user_role (
    id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    role_id BIGINT NOT NULL COMMENT '角色ID',
    UNIQUE KEY uk_user_role (user_id, role_id),
    INDEX idx_user (user_id),
    INDEX idx_role (role_id)
) COMMENT '用户角色关联表';

-- =====================================================
-- 6. 权限表（admin-svc）
-- =====================================================
DROP TABLE IF EXISTS t_permission;
CREATE TABLE t_permission (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    perm_name   VARCHAR(64)  NOT NULL    COMMENT '权限名称',
    perm_code   VARCHAR(128) NOT NULL    COMMENT '权限编码（如 emp:delete）',
    perm_type   VARCHAR(16)  DEFAULT 'BUTTON' COMMENT 'MENU/BUTTON',
    parent_id   BIGINT       DEFAULT 0   COMMENT '父权限ID',
    url         VARCHAR(255)             COMMENT '对应URL路径',
    sort_order  INT          DEFAULT 0,
    create_time DATETIME     DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_perm_code (perm_code)
) COMMENT '权限表';

-- =====================================================
-- 7. 角色-权限关联表（admin-svc）
-- =====================================================
DROP TABLE IF EXISTS t_role_permission;
CREATE TABLE t_role_permission (
    id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_id BIGINT NOT NULL COMMENT '角色ID',
    perm_id BIGINT NOT NULL COMMENT '权限ID',
    UNIQUE KEY uk_role_perm (role_id, perm_id)
) COMMENT '角色权限关联表';

-- =====================================================
-- 8. 审批表（admin-svc）— 自定义请假
-- =====================================================
DROP TABLE IF EXISTS t_approval;
CREATE TABLE t_approval (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    applicant_id    BIGINT       NOT NULL COMMENT '申请人ID',
    applicant_name  VARCHAR(64)  NOT NULL COMMENT '申请人姓名',
    dept_name       VARCHAR(64)              COMMENT '申请人部门',
    approver_id     BIGINT                  COMMENT '审批人ID（部门经理）',
    approver_name   VARCHAR(64)             COMMENT '审批人姓名',
    leave_type      VARCHAR(100) NOT NULL   COMMENT '请假类型（员工自由输入）',
    start_time      DATETIME     NOT NULL   COMMENT '开始时间',
    end_time        DATETIME     NOT NULL   COMMENT '结束时间',
    reason          TEXT         NOT NULL   COMMENT '请假事由',
    attachment      VARCHAR(255)            COMMENT '附件URL（可选）',
    status          TINYINT      DEFAULT 0  COMMENT '0=待审批 1=已通过 2=已驳回 3=已撤回',
    reject_reason   TEXT                    COMMENT '驳回理由（驳回时必填）',
    approve_time    DATETIME               COMMENT '审批时间',
    create_time     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    update_time     DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_applicant (applicant_id),
    INDEX idx_approver (approver_id),
    INDEX idx_status (status)
) COMMENT '审批表（自定义请假）';

-- =====================================================
-- 9. 公告表（admin-svc）
-- =====================================================
DROP TABLE IF EXISTS t_announcement;
CREATE TABLE t_announcement (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    title       VARCHAR(255) NOT NULL   COMMENT '公告标题',
    content     LONGTEXT     NOT NULL   COMMENT '公告内容（富文本）',
    publisher_id   BIGINT               COMMENT '发布人ID',
    publisher_name VARCHAR(64)          COMMENT '发布人姓名',
    status      TINYINT      DEFAULT 1  COMMENT '0=草稿 1=已发布 2=已撤回',
    create_time DATETIME     DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_create_time (create_time)
) COMMENT '公告表';

-- =====================================================
-- 10. 操作日志表（admin-svc）
-- =====================================================
DROP TABLE IF EXISTS t_audit_log;
CREATE TABLE t_audit_log (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT                  COMMENT '操作用户ID',
    username    VARCHAR(64)             COMMENT '操作用户名',
    operation   VARCHAR(128) NOT NULL   COMMENT '操作类型（如CREATE_EMP, APPROVE_LEAVE）',
    target_type VARCHAR(64)             COMMENT '操作对象类型',
    target_id   BIGINT                  COMMENT '操作对象ID',
    description TEXT                    COMMENT '操作描述',
    ip          VARCHAR(64)             COMMENT '操作IP',
    create_time DATETIME    DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_operation (operation),
    INDEX idx_create_time (create_time)
) COMMENT '操作日志表';

-- =====================================================
-- 初始化种子数据
-- =====================================================

-- 部门数据
INSERT INTO t_department (id, parent_id, dept_name, dept_code, sort_order) VALUES
(1, 0, '总公司',     'HQ',       1),
(2, 1, '技术部',     'TECH',     2),
(3, 1, '人事部',     'HR',       3),
(4, 1, '行政部',     'ADMIN',    4),
(5, 1, '财务部',     'FINANCE',  5);

-- 员工数据（密码均为 123456 的 BCrypt 加密值）
INSERT INTO t_employee (id, emp_no, name, gender, dept_id, dept_name, position, phone, email, status) VALUES
(1, 'EMP001', '张三', 1, 2, '技术部', 'Java开发工程师', '13800001001', 'zhangsan@example.com', 1),
(2, 'EMP002', '李四', 1, 2, '技术部经理',   '13800001002', 'lisi@example.com',     1),
(3, 'EMP003', '王五', 1, 3, '人事部', 'HR主管',        '13800001003', 'wangwu@example.com',    1),
(4, 'EMP004', '赵六', 2, 4, '行政部', '行政专员',      '13800001004', 'zhaoliu@example.com',  1),
(5, 'EMP005', '孙七', 1, 5, '财务部', '财务主管',      '13800001005', 'sunqi@example.com',    1);

-- 用户数据（密码统一为 123456，BCrypt 加密）
-- BCrypt for "123456": $2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5Eh
INSERT INTO t_user (id, username, password, real_name, emp_id, phone, email, status) VALUES
(1, 'admin',   '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5Eh', '系统管理员', NULL, '13800000001', 'admin@smartoa.com',   1),
(2, 'manager', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5Eh', '李四',       2,    '13800001002', 'lisi@smartoa.com',    1),
(3, 'zhangsan','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5Eh', '张三',       1,    '13800001001', 'zhangsan@smartoa.com', 1);

-- 角色数据
INSERT INTO t_role (id, role_name, role_code, description) VALUES
(1, '系统管理员', 'ADMIN',    '拥有全部权限'),
(2, '部门经理',   'MANAGER',  '可管理本部门员工、审批请假、发布公告'),
(3, '普通员工',   'EMPLOYEE', '可查看信息、提交请假、使用AI客服');

-- 用户-角色关联
INSERT INTO t_user_role (user_id, role_id) VALUES
(1, 1),  -- admin → ADMIN
(2, 2),  -- manager → MANAGER
(3, 3);  -- zhangsan → EMPLOYEE

-- 权限数据
INSERT INTO t_permission (id, perm_name, perm_code, perm_type, url) VALUES
(1,  '员工查看',   'emp:view',     'BUTTON', '/api/emp/**'),
(2,  '员工新增',   'emp:create',   'BUTTON', '/api/emp'),
(3,  '员工编辑',   'emp:update',   'BUTTON', '/api/emp/**'),
(4,  '员工删除',   'emp:delete',   'BUTTON', '/api/emp/**'),
(5,  '用户管理',   'user:manage',  'BUTTON', '/api/admin/user/**'),
(6,  '角色管理',   'role:manage',  'BUTTON', '/api/admin/role/**'),
(7,  '请假申请',   'approval:apply','BUTTON', '/api/admin/approval/submit'),
(8,  '请假审批',   'approval:audit','BUTTON', '/api/admin/approval/**'),
(9,  '公告管理',   'announce:manage','BUTTON','/api/admin/announcement/**'),
(10, '公告查看',   'announce:view', 'BUTTON', '/api/admin/announcement/list'),
(11, 'AI对话',     'ai:chat',       'BUTTON', '/api/ai/chat/**'),
(12, '日志查看',   'log:view',      'BUTTON', '/api/admin/log/**');

-- 角色-权限关联
-- ADMIN: 全部权限
INSERT INTO t_role_permission (role_id, perm_id)
SELECT 1, id FROM t_permission;

-- MANAGER: 员工查看+编辑，审批，公告管理，AI对话
INSERT INTO t_role_permission (role_id, perm_id) VALUES
(2, 1), (2, 3), (2, 8), (2, 9), (2, 10), (2, 11);

-- EMPLOYEE: 员工查看，请假申请，公告查看，AI对话
INSERT INTO t_role_permission (role_id, perm_id) VALUES
(3, 1), (3, 7), (3, 10), (3, 11);

-- 公告种子数据
INSERT INTO t_announcement (id, title, content, publisher_id, publisher_name, status) VALUES
(1, '关于台风期间远程办公的通知',
    '<p>受台风影响，7月16日-17日全体员工实行远程办公。请各部门负责人做好工作安排，确保业务连续性。如有紧急情况请及时联系行政部。</p>',
    1, '系统管理员', 1),
(2, '新入职员工培训安排',
    '<p>请各部门新入职员工于7月20日上午9:00在3楼会议室参加入职培训。培训内容包括：</p><ul><li>公司制度介绍</li><li>OA系统使用指南</li><li>安全生产教育</li></ul>',
    1, '系统管理员', 1);

-- 审批种子数据
INSERT INTO t_approval (id, applicant_id, applicant_name, dept_name, approver_id, approver_name,
                        leave_type, start_time, end_time, reason, status, approve_time) VALUES
(1, 3, '张三', '技术部', 2, '李四',
    '年假', '2026-07-20 09:00:00', '2026-07-22 18:00:00',
    '带家人外出旅游，已提前安排好工作交接', 0, NULL);
