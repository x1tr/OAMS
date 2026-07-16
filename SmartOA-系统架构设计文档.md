# SmartOA — 系统架构设计文档

---

## 文档信息

| 项目 | 内容 |
|------|------|
| **项目名称** | SmartOA — 企业智慧办公管理系统 |
| **文档类型** | 系统架构设计说明书 |
| **架构风格** | 微服务 + 前后端分离 + AI独立部署 |
| **版本** | V1.0 / 10天实训版 |

---

## 一、架构全景图

```
┌────────────────────────────────────────────────────────────────┐
│                    Vue.js 3 SPA (Vite, Port 5173)              │
│  登录页 │ 工作台 │ 员工管理 │ 请假审批 │ 公告 │ AI对话         │
└──────────────────────────┬─────────────────────────────────────┘
                           │ HTTP REST + SSE(AI流式)
                           ▼
┌────────────────────────────────────────────────────────────────┐
│              Gateway :8080 (Spring Cloud Gateway)              │
│  路由转发 │ JWT全局鉴权 │ CORS │ LoadBalancer                  │
│  /api/emp/** → emp-svc   /api/admin/** → admin-svc            │
│  /api/ai/**  → ai-svc    /api/auth/** → 直接放行              │
└──────┬──────────────────┬──────────────────┬──────────────────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
│ oa-emp-svc   │  │ oa-admin-svc │  │ oa-ai-svc            │
│ :8091        │  │ :8092        │  │ :8093                │
│ Boot 2.x     │  │ Boot 2.x     │  │ Boot 3.4.5 (独立)    │
│              │  │              │  │                      │
│ 员工CRUD     │  │ 用户/角色RBAC│  │ Ollama Chat (SSE)    │
│ 部门管理     │  │ ★灵活请假审批│  │ RAG 知识检索         │
│ ES员工检索   │  │ 公告管理     │  │ Embedding 向量化     │
│ PageHelper   │  │ ES公告检索   │  │ RedisStack 向量库    │
│ Druid连接池  │  │ Redis缓存    │  │ WebFlux              │
└──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘
       │                 │                      │
       └─────────────────┼──────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
    ┌──────────┐  ┌──────────┐  ┌──────────────┐
    │ MySQL    │  │ Redis    │  │ Elasticsearch│
    │ :3306    │  │ :6379    │  │ :9200/:9300  │
    │ 业务数据 │  │ 缓存+    │  │ 全文检索     │
    │ 8张表    │  │ Session  │  │ IK分词       │
    └──────────┘  └──────────┘  └──────────────┘
          ┌──────────────┬──────────────┐
          ▼              ▼              ▼
    ┌──────────┐  ┌──────────┐  ┌──────────────────┐
    │ Nacos    │  │ 无Redis  │  │ Ollama           │
    │ :8848    │  │ Stack    │  │ :11434           │
    │ 注册+配置│  │ (内存模式)│  │ qwen2.5:0.5b     │
    │          │  │          │  │ + nomic-embed    │
    └──────────┘  └──────────┘  └──────────────────┘
    
    ★ 向量检索使用JDK内存实现，零额外中间件依赖
```

---

## 二、各服务详细设计

### 2.1 Gateway 网关

**唯一入口，不碰业务数据，不连数据库。**

```
请求生命周期：
Request → CorsFilter → AuthFilter(JWT校验) → Route → 下游服务

路由表：
  /api/auth/login       → 直接放行（登录不需要Token）
  /api/auth/register    → 直接放行（如有注册需求）
  /api/emp/**           → lb://oa-emp-service    + Bearer Token
  /api/admin/**         → lb://oa-admin-service  + Bearer Token
  /api/ai/**            → lb://oa-ai-service     + Bearer Token

JWT校验逻辑：
  1. 从 Header 取 Authorization: Bearer <token>
  2. 解析JWT → 取userId + role
  3. 查Redis验证Token未过期/未被踢下线
  4. 放行，将userId写入请求Header传给下游
```

---

### 2.2 oa-emp-service 员工服务

```
项目结构：
oa-emp-service/
├── controller/
│   ├── EmployeeController      "员工CRUD API"
│   ├── DepartmentController    "部门管理 API"
│   └── SearchController        "ES搜索 API  GET /api/emp/search?keyword=张三"
├── service/
│   ├── EmployeeService         "业务逻辑 + ES同步"
│   └── DepartmentService
├── mapper/
│   ├── EmployeeMapper          "MyBatis XML映射"
│   └── DepartmentMapper
├── repository/
│   └── EmployeeEsRepository    "ES Repository extends ElasticsearchRepository"
├── entity/
│   ├── Employee                "MySQL实体"
│   └── EmployeeDocument        "ES文档实体(@Document)"
└── config/
    └── ElasticsearchConfig     "ES客户端配置"
```

**数据同步策略**：
```
MySQL 写入成功
    │
    ▼
同步更新 ES 索引 (try-catch包裹，失败不影响主流程)
    │
    ▼
ES 索引名：smart_oa_employee
字段：id, empNo, name, deptName, position, email, phone
分析器：ik_max_word (索引时) / ik_smart (搜索时)
```

**ES 搜索 API 设计**：
```
GET /api/emp/search?keyword=张三&deptId=1&page=1&size=10

ES查询：
  - bool query: must(keyword多字段match) + filter(deptId精确匹配)
  - highlight: name/position字段高亮 <em>标签
  - from/size 分页

返回：
{
  "total": 25,
  "list": [
    { "id":1, "name":"张三", "deptName":"技术部", 
      "highlight": { "name": "<em>张三</em>" } }
  ]
}
```

---

### 2.3 oa-admin-service 管理服务

这是最复杂的服务，做四件事：RBAC、请假审批、公告、日志。

```
项目结构：
oa-admin-service/
├── controller/
│   ├── AuthController           "POST /api/admin/auth/login"
│   ├── UserController           "用户CRUD(管理员)"
│   ├── RoleController           "角色管理"
│   ├── ApprovalController       "★ 请假申请/审批"
│   ├── AnnouncementController   "公告CRUD + ES搜索"
│   └── LogController            "操作日志查询"
├── service/
│   ├── UserService              "用户服务(Redis缓存)"
│   ├── ApprovalService          "请假流程引擎"
│   ├── AnnouncementService      "公告服务(ES同步)"
│   └── AuditLogService          "AOP切面记录日志"
├── security/
│   ├── JwtTokenProvider         "JWT 生成/解析"
│   ├── JwtAuthFilter            "认证过滤器"
│   ├── UserDetailsServiceImpl   "加载用户+权限"
│   └── SecurityConfig           "SpringSecurity配置"
├── mapper/
│   ├── UserMapper, RoleMapper, PermissionMapper
│   ├── ApprovalMapper, AnnouncementMapper
├── config/
│   └── RedisConfig              "RedisTemplate + 序列化"
└── annotation/
    └── AuditLog                 "自定义操作日志注解"
```

#### ★ 自定义请假系统 — 核心设计

**为什么不设固定请假类型下拉框？**

传统做法是在数据库建一张 `t_leave_type` 字典表，存"年假/事假/病假/婚假"等固定选项。这有四个问题：
1. 企业之间假期分类差异大，一套字典无法适配所有公司
2. 员工需求多样——"接孩子""考证""远程办公"这类非标需求装不进固定分类
3. 字典表需要管理员维护，增加系统复杂度
4. 用户在选项中找不到自己的情况时体验很差

**我们的设计**：`leave_type` 字段改为 `VARCHAR(100)`，前端从 `<el-select>` 改为 `<el-input>`，员工自己打字。

**数据表**：

```sql
CREATE TABLE t_approval (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    applicant_id    BIGINT        NOT NULL COMMENT '申请人ID',
    applicant_name  VARCHAR(64)   NOT NULL COMMENT '申请人姓名',
    approver_id     BIGINT        COMMENT '审批人ID（部门经理）',
    approver_name   VARCHAR(64)   COMMENT '审批人姓名',
    
    -- ★ 核心字段：自由文本，非外键关联
    leave_type      VARCHAR(100)  NOT NULL COMMENT '请假类型（员工自由输入，如"年假""考证""远程办公"）',
    start_time      DATETIME      NOT NULL COMMENT '开始时间',
    end_time        DATETIME      NOT NULL COMMENT '结束时间',
    reason          TEXT          NOT NULL COMMENT '请假事由（员工自由填写）',
    attachment      VARCHAR(255)  COMMENT '附件URL（可选，如医院证明图片）',
    
    status          TINYINT       DEFAULT 0 COMMENT '0=待审批 1=已通过 2=已驳回 3=已撤回',
    reject_reason   TEXT          COMMENT '驳回理由（驳回时必填）',
    approve_time    DATETIME      COMMENT '审批时间',
    create_time     DATETIME      DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_applicant (applicant_id),
    INDEX idx_approver  (approver_id),
    INDEX idx_status    (status)
);
```

**API 设计**：

```
POST /api/admin/approval/submit           "提交请假申请"
  Body: {
    "leaveType": "考证",           ← 自由文本
    "startTime": "2026-07-16 08:00",
    "endTime": "2026-07-18 18:00",
    "reason": "参加PMP项目管理认证考试，考点在杭州，需要三天时间",
    "attachment": "/uploads/2026/07/准考证.pdf"   ← 可选
  }

GET /api/admin/approval/my-applications?page=1&size=10
  "查看我的申请列表（普通员工视角）"

GET /api/admin/approval/pending?page=1&size=10
  "查看待我审批列表（经理视角）"

POST /api/admin/approval/{id}/approve      "经理通过"
  Body: {}

POST /api/admin/approval/{id}/reject        "经理驳回"
  Body: { "reason": "请补充培训机构的报名证明材料" }
```

**审批状态机**：

```
    [员工提交]
        │
        ▼
   ┌─────────┐
   │  待审批  │ (status=0)
   └────┬─────┘
        │
   ┌────┴────┐
   ▼         ▼
┌──────┐  ┌──────┐
│ 通过  │  │ 驳回  │
│(1)   │  │(2)   │
└──────┘  └──┬───┘
             │ (员工修改后重新提交)
             ▼
        ┌─────────┐
        │  待审批  │ (回到status=0)
        └─────────┘

员工也可在审批前撤回 (status=3)
```

#### RBAC 权限模型

```
t_user ──多对多──▶ t_user_role ──多对多──▶ t_role
                                               │
                                          t_role_perm
                                               │
                                               ▼
                                          t_permission
                                          (perm_type: MENU / BUTTON)
```

**三种预设角色**：

| 角色 | role_code | 典型权限 |
|------|------|------|
| 管理员 | ADMIN | 全部菜单 + 全部按钮 |
| 部门经理 | MANAGER | 员工查看 + 审批 + 公告管理 |
| 普通员工 | EMPLOYEE | 员工查看 + 请假申请 + AI客服 + 公告查看 |

#### Redis 缓存策略

| 缓存Key | 内容 | TTL | 失效时机 |
|------|------|------|------|
| `user:{id}` | 用户基本信息 | 30min | 用户信息修改时删除 |
| `role:perm:{roleId}` | 角色的权限列表 | 1h | 角色权限变更时删除 |
| `dept:tree` | 部门树JSON | 1h | 部门增删改时删除 |
| `session:{token}` | 登录会话 | 2h | 退出登录或管理员踢人 |

---

### 2.4 oa-ai-service AI智能客服

**独立POM、独立技术栈、独立启动**。与其他服务通过Gateway HTTP互通。

```
oa-ai-service (Spring Boot 3.4.5 + Spring AI 1.0.0)
│
├── controller/
│   └── ChatController
│       POST /api/ai/chat/stream          "流式对话(SSE) → Flux<String>"
│       POST /api/ai/knowledge/upload     "上传知识文档"
│       GET  /api/ai/knowledge/list       "知识库列表"
│
├── service/
│   ├── OllamaChatService     "调用Ollama Chat API"
│   ├── RagService            "RAG：检索+组装+生成"
│   ├── EmbeddingService      "文档向量化"
│   └── KnowledgeService      "知识库文档管理"
│
├── config/
│   ├── OllamaConfig          "Ollama连接配置"
│   ├── MemoryVectorConfig    "内存向量库配置（JDK内置，无需外部依赖）"
│   └── WebFluxConfig         "SSE CORS配置"
│
└── entity/
    └── KnowledgeDocument     "知识库文档实体"
```

**RAG 问答全流程**：

```
① 用户问题       "请假需要什么材料？"
      │
      ▼
② Embedding      Ollama nomic-embed-text → 768维向量
      │
      ▼
③ 向量检索        内存向量相似度计算（JDK Map实现，无需RedisStack）
   返回Top-3相关文档片段：
   示例结果：
   ┌──────────────────────────────────────────────────────┐
   │ 文档：《考勤管理制度》§3.4                            │
   │ 内容：病假需提交医院挂号单和诊断证明……                │
   │ 相似度：0.89                                         │
   ├──────────────────────────────────────────────────────┤
   │ 文档：《员工手册》§2.1                                │
   │ 内容：年假需提前3个工作日提交申请……                   │
   │ 相似度：0.82                                         │
   └──────────────────────────────────────────────────────┘
      │
      ▼
④ 组装 Prompt     System: "你是SmartOA助手，仅根据以下制度文档回答。
                           如果文档中没有相关信息，请诚实告知。"
                   Context: [检索到的文档片段]
                   User: "请假需要什么材料？"
      │
      ▼
⑤ AI 生成         Ollama qwen2.5:0.5b → Flux<String> 逐Token
      │
      ▼
⑥ SSE 推送        text/event-stream
                   data: 根
                   data: 据
                   data: 公司
                   data: 制度
                   data: ，病
                   data: 假
                   data: 需要
                   data: ...
      │
      ▼
⑦ 前端逐字渲染    AI对话气泡中逐字显示
```

**★ 内存向量库（默认方案，零额外依赖）**：

oa-ai-service **默认使用内存向量库**，基于 JDK 自带的 `HashMap<String, float[]>` + 余弦相似度算法。不需要安装 Docker 或 RedisStack。知识库文档在服务启动时自动从本地文件加载并向量化到内存中。

```yaml
# application.yml（默认配置，无需修改）
ai:
  assistant:
    vector-mode: memory     # 内存向量存储（默认）
    knowledge-dir: classpath:/knowledge   # 3-5篇制度文档存放位置
```

- ✅ 零外部依赖 — 不需要 Docker、不需要 RedisStack
- ✅ 8GB 内存即可 — 几百条文档片段 + 768维向量的内存占用 < 50MB
- ⚠️ 数据重启丢失 — 每次启动需重新向量化（知识库文档保留在磁盘，启动时自动重建索引）
- ⚠️ 知识库规模受限 — 仅适合几百条文档量级（实训场景完全够用）

> **如需扩展到生产级**，将 `vector-mode` 改为 `redis` 并配置 RedisStack 连接即可，代码零改动。

---

## 三、数据库表汇总

| # | 表名 | 所属服务 | 说明 |
|------|------|------|------|
| 1 | t_employee | emp-svc | 员工信息 |
| 2 | t_department | emp-svc | 部门树 |
| 3 | t_user | admin-svc | 登录用户 |
| 4 | t_role | admin-svc | 角色 |
| 5 | t_user_role | admin-svc | 用户-角色关系 |
| 6 | t_permission | admin-svc | 权限 |
| 7 | t_role_permission | admin-svc | 角色-权限关系 |
| 8 | t_approval | admin-svc | ★ 请假审批（自由类型） |
| 9 | t_announcement | admin-svc | 公告 |
| 10 | t_audit_log | admin-svc | 操作日志 |

---

## 四、API 汇总

| 方法 | 路径 | 服务 | 鉴权 | 说明 |
|------|------|------|------|------|
| POST | `/api/auth/login` | admin | 放行 | 登录，返回JWT |
| GET | `/api/emp/list` | emp | ✅ | 员工分页列表 |
| GET | `/api/emp/{id}` | emp | ✅ | 员工详情 |
| POST | `/api/emp` | emp | ✅ | 新增员工 |
| PUT | `/api/emp/{id}` | emp | ✅ | 修改员工 |
| DELETE | `/api/emp/{id}` | emp | ✅ | 删除员工 |
| GET | `/api/emp/search` | emp | ✅ | ES搜索员工 |
| GET | `/api/admin/user/list` | admin | ✅ | 用户列表 |
| POST | `/api/admin/approval/submit` | admin | ✅ | ★ 提交请假 |
| GET | `/api/admin/approval/my` | admin | ✅ | 我的申请 |
| GET | `/api/admin/approval/pending` | admin | ✅ | 待审批 |
| POST | `/api/admin/approval/{id}/approve` | admin | ✅ | 通过 |
| POST | `/api/admin/approval/{id}/reject` | admin | ✅ | 驳回(含理由) |
| GET | `/api/admin/announcement/list` | admin | ✅ | 公告列表 |
| GET | `/api/admin/announcement/search` | admin | ✅ | ES搜索公告 |
| POST | `/api/ai/chat/stream` | ai | ✅ | SSE流式对话 |
| POST | `/api/ai/knowledge/upload` | ai | ✅ | 上传知识文档 |

---

## 五、部署架构（开发环境）

```
一台 Windows 电脑运行全部服务：

┌─────────────────────────────────────────┐
│ Docker (或本地安装)                      │
│  MySQL:3306     Redis:6379              │
│  RedisStack:6380  ES:9200              │
│  Nacos:8848      Ollama:11434          │
├─────────────────────────────────────────┤
│ IDEA 中启动4个微服务：                   │
│  Gateway:8080                           │
│  oa-emp-service:8091                    │
│  oa-admin-service:8092                  │
│  oa-ai-service:8093                     │
├─────────────────────────────────────────┤
│ VS Code 启动前端：                       │
│  npm run dev → localhost:5173           │
└─────────────────────────────────────────┘

总计：8个端口，约需 8GB 内存
```

---

## 六、关键设计决策

| 决策 | 为什么 |
|------|------|
| AI服务独立Boot 3.x | Spring AI 1.0 强制要求，不能迁就主工程的Boot 2.x |
| 请假类型用自由文本而非字典表 | 适配性更好，去掉不必要的配置维护，学生更容易理解 |
| ES同步用try-catch包裹 | ES不可用时不影响主业务流程（降级为仅MySQL搜索） |
| 驳回必填理由 | 强制管理者给出明确反馈，形成沟通闭环 |
| OSS图片用本地存储代替 | 10天实训不需要搞对象存储，本地文件即可 |
| 内存向量库降级方案 | 不用Docker的学生也能跑AI模块 |
