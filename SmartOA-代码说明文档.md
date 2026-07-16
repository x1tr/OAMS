# SmartOA — 代码说明文档

---

## 文档信息

| 项目 | 内容 |
|------|------|
| **项目名称** | SmartOA — 企业智慧办公管理系统 |
| **文档类型** | 代码说明 / README |
| **版本** | V1.0 |
| **代码总文件数** | 111 个 |
| **后端** | 79 个文件（4 个微服务 + 1 个公共模块） |
| **前端** | 28 个文件（Vue.js 3 SPA） |
| **数据库** | 1 个 SQL 脚本（10 张表 + 种子数据） |
| **AI 知识库** | 3 篇制度文档 |

---

## 一、项目目录总览

```
D:\OAManagementSystem\
│
├── smart-oa-backend/                    # 后端 Maven 多模块项目
│   ├── pom.xml                          # 父 POM（统一依赖管理）
│   │
│   ├── smart-oa-common/                 # 公共模块（5 个文件）
│   │   └── src/main/java/com/smartoa/common/
│   │       ├── result/
│   │       │   ├── R.java               # 统一响应封装
│   │       │   └── ResultCode.java      # 响应状态码枚举
│   │       ├── util/
│   │       │   └── JwtUtil.java         # JWT 工具类
│   │       └── exception/
│   │           └── BusinessException.java # 业务异常
│   │
│   ├── smart-oa-gateway/                # 网关模块（5 个文件）:8080
│   │   └── src/main/java/com/smartoa/gateway/
│   │       ├── GatewayApplication.java  # 启动类
│   │       ├── filter/
│   │       │   └── AuthFilter.java      # JWT 全局鉴权过滤器
│   │       └── config/
│   │           └── CorsConfig.java      # 跨域配置
│   │
│   ├── oa-emp-service/                  # 员工服务（16 个文件）:8091
│   │   └── src/main/java/com/smartoa/emp/
│   │       ├── EmpServiceApplication.java
│   │       ├── entity/                  # Employee, Department, EmployeeDocument
│   │       ├── mapper/                  # EmployeeMapper, DepartmentMapper
│   │       ├── repository/              # EmployeeEsRepository (ES)
│   │       ├── service/                 # EmployeeService, DepartmentService
│   │       └── controller/              # EmployeeController, SearchController, DepartmentController
│   │
│   ├── oa-admin-service/                # 管理服务（40 个文件）:8092
│   │   └── src/main/java/com/smartoa/admin/
│   │       ├── AdminServiceApplication.java
│   │       ├── entity/                  # User, Role, Permission, Approval, Announcement, AnnouncementDocument, AuditLog
│   │       ├── mapper/                  # 6 个 Mapper 接口
│   │       ├── repository/              # AnnouncementEsRepository
│   │       ├── security/                # JwtTokenProvider, JwtAuthFilter, UserDetailsServiceImpl, SecurityConfig
│   │       ├── service/                 # UserService, ApprovalService, AnnouncementService, AuditLogService
│   │       ├── controller/              # AuthController, UserController, RoleController, ApprovalController, AnnouncementController, LogController
│   │       ├── annotation/              # @AuditLog 注解
│   │       ├── aop/                     # AuditLogAspect 切面
│   │       └── config/                  # RedisConfig
│   │
│   └── oa-ai-service/                   # AI 客服（12 个文件，Boot 3.4.5 独立）:8093
│       └── src/main/java/com/smartoa/ai/
│           ├── AiServiceApplication.java
│           ├── entity/                  # KnowledgeDocument
│           ├── config/                  # OllamaConfig, WebFluxConfig
│           ├── service/                 # MemoryVectorStore, EmbeddingService, KnowledgeService, OllamaChatService, RagService
│           └── controller/              # ChatController
│
├── smart-oa-frontend/                   # 前端 Vue.js 3（28 个文件）:5173
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── index.html
│   └── src/
│       ├── main.ts                      # 入口
│       ├── App.vue                      # 根组件（布局切换）
│       ├── styles/tokens.css            # Design Token（CSS 变量）
│       ├── api/                         # 4 个 API 模块
│       │   ├── request.ts               # Axios 实例 + 拦截器
│       │   ├── emp.ts                   # 员工 API
│       │   ├── admin.ts                 # 管理/审批/公告 API
│       │   └── ai.ts                    # AI 对话 API
│       ├── stores/                      # 3 个 Pinia Store
│       │   ├── user.ts                  # 用户状态（登录/角色/Token）
│       │   ├── app.ts                   # 应用状态（侧栏折叠）
│       │   └── chat.ts                  # AI 对话历史
│       ├── router/index.ts              # 7 条路由 + 角色守卫
│       ├── composables/useSSE.ts        # SSE 流式接收 Hook
│       ├── components/
│       │   ├── layout/
│       │   │   ├── AppSidebar.vue       # 侧栏导航（呼吸指示器）
│       │   │   └── AppTopbar.vue        # 顶栏（面包屑 + 用户菜单）
│       │   ├── ApprovalForm.vue         # 自定义请假表单
│       │   └── AiMessage.vue            # AI 消息气泡（流式渲染）
│       └── views/                       # 7 个页面
│           ├── LoginView.vue            # 登录页
│           ├── DashboardView.vue        # 工作台首页
│           ├── EmployeeView.vue         # 员工管理
│           ├── ApprovalView.vue         # 审批中心
│           ├── AnnouncementView.vue     # 公告通知
│           ├── AiChatView.vue           # AI 对话
│           └── SettingsView.vue         # 系统设置
│
├── sql/
│   └── init.sql                         # 数据库初始化（建表 + 种子数据）
│
├── knowledge/                           # AI 知识库文档
│   ├── 考勤管理制度.txt
│   ├── 员工手册.txt
│   └── 报销制度.txt
│
└── [设计文档]
    ├── SmartOA-项目总纲.md
    ├── SmartOA-项目视图与范围文档.md
    ├── SmartOA-系统架构设计文档.md
    ├── SmartOA-前端设计规范.md
    ├── SmartOA-开发环境搭建指南.md
    ├── SmartOA-可行性分析报告.md
    └── SmartOA-前后端测试需求文档.md
```

---

## 二、模块详情

### 2.1 smart-oa-common（公共模块）

被所有业务服务依赖，提供统一的基础能力。

| 文件 | 职责 | 关键方法 |
|------|------|---------|
| `R.java` | 统一响应 `R<T> {code, msg, data}` | `R.ok()` / `R.ok(data)` / `R.fail(code, msg)` |
| `ResultCode.java` | 状态码枚举 | `SUCCESS(200)`, `UNAUTHORIZED(401)`, `FORBIDDEN(403)`, `PARAM_ERROR(400)`, `SERVER_ERROR(500)` |
| `JwtUtil.java` | JWT 生成/解析/验证 | `createToken(userId, username, role)` → 2h 过期<br>`parseToken(token)` → Claims<br>`validate(token)` → boolean |
| `BusinessException.java` | 业务异常 | `RuntimeException(code, msg)` 子类 |

---

### 2.2 smart-oa-gateway（网关，端口 8080）

**职责**：统一入口，JWT 鉴权 + 路由转发。不连接数据库。

**路由表**：

| 路由前缀 | 转发目标 | 鉴权 |
|----------|---------|------|
| `/api/auth/login` | oa-admin-service | 🔓 放行 |
| `/api/emp/**` | oa-emp-service | 🔒 Bearer Token |
| `/api/admin/**` | oa-admin-service | 🔒 Bearer Token |
| `/api/ai/**` | oa-ai-service | 🔒 Bearer Token |

**AuthFilter 鉴权流程**：

```
1. 跳过 /api/auth/login
2. 提取 Header: Authorization: Bearer <token>
3. JwtUtil.parseToken(token) → 解析失败返回 401
4. JwtUtil.isExpired(claims) → 过期返回 401
5. Redis 检查 session:{token} 是否存在 → 不存在返回 401
6. 放行
```

---

### 2.3 oa-emp-service（员工服务，端口 8091）

**职责**：员工 CRUD + 部门管理 + ES 全文搜索。

**技术栈**：Spring Boot 2.7.18 + MyBatis + PageHelper + Elasticsearch 7.13 + MySQL

| 分层 | 文件 | 说明 |
|------|------|------|
| Entity | `Employee.java` | MySQL 实体（id, empNo, name, deptId, position, phone, email...） |
| Entity | `Department.java` | 部门树（id, parentId, deptName, deptCode） |
| Entity | `EmployeeDocument.java` | ES 文档（`@Document(indexName="smart_oa_employee")`，IK 分词） |
| Mapper | `EmployeeMapper.java` + XML | CRUD + 动态条件分页查询 |
| Mapper | `DepartmentMapper.java` + XML | CRUD + 递归树查询 |
| Repository | `EmployeeEsRepository.java` | ES Repository，扩展自 `ElasticsearchRepository` |
| Service | `EmployeeService.java` | 核心逻辑：CRUD → MySQL → try-catch ES 同步 → 返回<br>脱敏：`getMaskedPhone("138****5678")` |
| Service | `DepartmentService.java` | 部门 CRUD + 树 |
| Controller | `EmployeeController.java` | RESTful：`GET/POST/PUT/DELETE /api/emp/**` |
| Controller | `SearchController.java` | `GET /api/emp/search?keyword=&deptId=&page=&size=` → ES bool query + 高亮 |
| Controller | `DepartmentController.java` | `GET /api/dept/tree` |

**ES 降级策略**：

```java
try {
    employeeEsRepository.save(doc);
} catch (Exception e) {
    log.error("ES 同步失败，不影响主流程", e);
}
```

---

### 2.4 oa-admin-service（管理服务，端口 8092）

**职责**：登录认证 + RBAC 权限 + 自定义请假审批 + 公告管理 + Redis 缓存 + 操作审计日志。本项目最复杂的服务。

**技术栈**：Spring Boot 2.7.18 + Spring Security + MyBatis + Redis + Elasticsearch + AOP

#### 实体层（7 个 Entity）

| Entity | 对应表 | 核心字段 |
|--------|--------|---------|
| `User` | t_user | username, password(BCrypt), realName, status |
| `Role` | t_role | roleName, roleCode(ADMIN/MANAGER/EMPLOYEE) |
| `Permission` | t_permission | permName, permCode(emp:delete), permType(MENU/BUTTON) |
| `Approval` | t_approval | **leaveType(自由文本)** , startTime, endTime, reason, status(0/1/2/3) |
| `Announcement` | t_announcement | title, content(富文本), status |
| `AnnouncementDocument` | ES 索引 | title, content (IK 分词) |
| `AuditLog` | t_audit_log | userId, operation, description, ip |

#### 安全层（4 个类）

| 类 | 职责 |
|------|------|
| `JwtTokenProvider` | JWT 创建/解析/验证封装 |
| `JwtAuthFilter` | `OncePerRequestFilter`：拦截请求 → 解析 Token → 构建 SecurityContext |
| `UserDetailsServiceImpl` | 从 DB 加载用户+角色+权限 → SpringSecurity User |
| `SecurityConfig` | CSRF 关闭、Session 无状态、BCrypt 密码编码器、放行 `/api/auth/login` |

#### 服务层（4 个 Service）

| Service | 核心方法 | 关键逻辑 |
|---------|---------|---------|
| `UserService` | `login(username, pwd)` | BCrypt 验证 → JWT 生成 → Redis 存 session（TTL 2h） |
| | `getById(id)` | Redis 缓存 `user:{id}`（TTL 30min），命中直接返回 |
| | `create/update/delete` | 更新时删除 Redis 缓存 |
| `ApprovalService` | `submit(approval)` | 自动查找同部门 MANAGER → 设 approverId |
| | `approve(id, userId)` | **状态校验**：只有 status=0 可审批 → status=1 |
| | `reject(id, userId, reason)` | **理由校验**：非空 → status=2 |
| | `withdraw(id, userId)` | **权限校验**：只有本人 + status=0 可撤回 → status=3 |
| `AnnouncementService` | CRUD + ES 搜索 | 写操作同步 ES（try-catch 降级） |
| `AuditLogService` | `record()` / `queryPage()` | 记录操作日志 |

**审批状态机**：

```
         员工提交
            │
            ▼
      ┌──────────┐
      │ status=0 │ 待审批
      └─────┬────┘
            │
     ┌──────┼──────┐
     ▼      ▼      ▼
  status=1 status=2 status=3
  已通过    已驳回    已撤回
            │
     (员工修改后重新提交)
            ▼
      ┌──────────┐
      │ status=0 │ 重新待审批
      └──────────┘
```

**合法转换**：`0→1` `0→2` `0→3` `2→0`（其他转换均拒绝）

#### 控制器层（6 个 Controller）

| Controller | 端点 | 说明 |
|------------|------|------|
| `AuthController` | `POST /api/auth/login` | 登录 → 返回 `{token, userId, username, role}` |
| | `POST /api/auth/logout` | 退出 → 删除 Redis session |
| `UserController` | `GET/POST/PUT/DELETE /api/admin/user/**` | 用户 CRUD（管理员） |
| `RoleController` | `GET /api/admin/role/list` | 角色列表 |
| `ApprovalController` | `POST /api/admin/approval/submit` | 提交请假（leaveType 自由文本） |
| | `GET /api/admin/approval/my` | 我的申请列表 |
| | `GET /api/admin/approval/pending` | 待我审批列表 |
| | `POST /api/admin/approval/{id}/approve` | 通过 |
| | `POST /api/admin/approval/{id}/reject` | 驳回（`{reason}` 必填！） |
| | `PUT /api/admin/approval/{id}/withdraw` | 撤回 |
| `AnnouncementController` | 标准 CRUD + `GET /api/admin/announcement/search` | ES 搜索公告 |
| `LogController` | `GET /api/admin/log/list` | 操作日志查询 |

#### AOP 审计（2 个类）

```java
@AuditLog(operation = "CREATE_USER", targetType = "USER")
public R<User> create(...) { ... }
```

`AuditLogAspect` 通过 `@Around` 切面拦截 → 提取 userId + IP → 调用 `AuditLogService.record()` → **非阻塞**（失败不影响业务）。

#### Redis 缓存策略

| Key | 内容 | TTL | 失效时机 |
|-----|------|-----|---------|
| `user:{id}` | 用户信息 JSON | 30min | 修改/删除用户时 |
| `session:{token}` | 登录会话 | 2h | 退出/管理员踢人 |

---

### 2.5 oa-ai-service（AI 客服，端口 8093）

**职责**：基于 RAG 的企业制度智能问答，SSE 流式输出。

> ⚠️ **独立技术栈**：Spring Boot 3.4.5 + Spring AI 1.0.0 + WebFlux。不能与主工程（Boot 2.7）合并编译，独立 POM。

**技术栈**：Spring Boot 3.4.5 + Spring AI 1.0 + WebFlux + Ollama（本地模型）

| 分层 | 文件 | 说明 |
|------|------|------|
| Config | `OllamaConfig.java` | Ollama 连接配置（Spring AI 自动装配） |
| Config | `WebFluxConfig.java` | CORS 配置（SSE 跨域支持） |
| Entity | `KnowledgeDocument.java` | 知识文档：id, title, content, chunks, createTime |
| Service | `MemoryVectorStore.java` | **内存向量库**：`HashMap<String, float[]>` + 余弦相似度 |
| Service | `EmbeddingService.java` | 调 Ollama `/api/embeddings` → `float[]`（768 维） |
| Service | `KnowledgeService.java` | 启动加载 `.txt` 文件 → 切片（500 chars）→ 向量化 → 存 MemoryVectorStore |
| Service | `OllamaChatService.java` | 调 Ollama `/api/chat`（stream: true），解析 SSE 返回 Flux |
| Service | `RagService.java` | **RAG 全链路**：问题向量化 → Top-K 检索 → 组装 Prompt → AI 生成 |
| Controller | `ChatController.java` | REST API（见下方） |

**API 端点**：

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/ai/chat/stream` | SSE 流式对话（`text/event-stream`），返回 `data: 文本` ... `data: [DONE]` |
| `POST` | `/api/ai/chat` | 非流式对话（一次性返回） |
| `GET` | `/api/ai/knowledge/list` | 知识库文档列表 |
| `POST` | `/api/ai/knowledge/upload` | 上传知识文档 |
| `GET` | `/api/ai/suggestions` | 推荐问题列表 |

**RAG 全流程**：

```
用户问题："请假需要什么材料？"
    │
    ▼
① EmbeddingService.embed()
   Ollama nomic-embed-text → float[768]
    │
    ▼
② MemoryVectorStore.search()
   余弦相似度计算 → Top-3 文档片段
    │
    ▼
③ RagService.buildPrompt()
   System: "你是SmartOA助手，严格根据以下文档回答..."
   Context: [检索到的文档片段]
    │
    ▼
④ OllamaChatService.chatStream()
   WebFlux → Ollama /api/chat (stream:true)
    │
    ▼
⑤ Flux<ServerSentEvent<String>>
   data: 根 → data: 据 → data: 公 → data: 司 → ... → data: [DONE]
```

**内存向量库**：
- 实现：`HashMap<String, float[]>` + 余弦相似度
- 容量：几百条文档片段 + 768 维向量 < 50MB 内存
- 优点：零外部依赖（不需要 Docker、RedisStack）
- 限制：重启后需重建索引（知识库文件保留在磁盘，启动时自动加载）
- 扩展：改一行配置 `vector-mode: redis` 即可切换生产级向量库

---

### 2.6 smart-oa-frontend（前端，端口 5173）

**技术栈**：Vue.js 3.4+ + Element Plus 2.6+ + Pinia 2.1+ + Vue Router 4.3+ + Axios 1.6+ + Vite 5.2+

#### 文件说明

##### 入口与配置

| 文件 | 说明 |
|------|------|
| `package.json` | 依赖清单 + 脚本（dev/build/preview） |
| `vite.config.ts` | Vite 配置 + `/api` → `localhost:8080` 代理 |
| `tsconfig.json` | TypeScript 编译配置 |
| `index.html` | HTML 入口 |
| `src/main.ts` | 应用启动：`createApp` → `use(ElementPlus)` → `use(Pinia)` → `use(Router)` |
| `src/App.vue` | 根组件：登录页直接渲染，其他页面 = 侧栏 + 顶栏 + `<router-view>` |

##### 设计系统

| 文件 | 说明 |
|------|------|
| `src/styles/tokens.css` | CSS 自定义属性：颜色（`--color-primary: #2563EB` / `--color-ai: #7C3AED`）、间距（4px 基准）、圆角（4/6/10px）、阴影（3 级） |

##### API 层（4 个文件）

| 文件 | 说明 |
|------|------|
| `request.ts` | Axios 实例：baseURL `/api`，自动注入 Bearer Token，401→重定向登录 |
| `emp.ts` | 员工 API：`getEmpList` / `searchEmp` / `createEmp` / `updateEmp` / `deleteEmp` / `getDeptTree` |
| `admin.ts` | 管理 API：`login` / `logout` / 用户CRUD / `submitApproval` / `approveApplication` / `rejectApplication` / 公告CRUD / 日志查询 |
| `ai.ts` | AI API：`chatOnce` / `getKnowledgeList` / `getSuggestions` |

##### 状态管理（3 个 Store）

| Store | 核心 State | 说明 |
|-------|-----------|------|
| `user.ts` | `token, userId, username, role` | `login()` → 调 API → 存 localStorage<br>`logout()` → 清除全部<br>`isLoggedIn/isAdmin/isManager` 计算属性 |
| `app.ts` | `sidebarCollapsed` | 侧栏折叠/展开 |
| `chat.ts` | `conversations[], currentConversationId` | AI 对话历史管理 |

##### 路由（1 个文件）

| 路由 | 页面 | 权限 |
|------|------|------|
| `/login` | LoginView | 🔓 无需登录 |
| `/dashboard` | DashboardView | 🔒 需登录 |
| `/employees` | EmployeeView | 🔒 需登录 |
| `/approval` | ApprovalView | 🔒 需登录 |
| `/announcements` | AnnouncementView | 🔒 需登录 |
| `/ai-chat` | AiChatView | 🔒 需登录 |
| `/settings` | SettingsView | 🔒 仅 ADMIN |

路由守卫：`router.beforeEach` 检查登录状态 + 角色权限。

##### 可组合函数

| 文件 | 说明 |
|------|------|
| `useSSE.ts` | SSE 流式接收：`sendMessage(question)` → `Fetch API` + `ReadableStream` → 逐行解析 `data: ` → 动态追加 `text.value`。支持 `stop()` 中断。 |

##### 组件（4 个）

| 组件 | 说明 |
|------|------|
| `AppSidebar.vue` | 深色侧栏（240px/64px），当前页 **3px 彩色呼吸指示器**（800ms 渐变），折叠/悬停展开 |
| `AppTopbar.vue` | 白色顶栏（56px），面包屑 + 用户头像 + 角色标签 + 退出 |
| `ApprovalForm.vue` | ★ **请假类型用 `<el-input>` 自由文本**（非下拉），日期选择器，文本域事由，附件上传 |
| `AiMessage.vue` | AI 消息：左侧 3px 紫色边框 `#7C3AED`，流式时末尾紫色闪烁光标 `▊`<br>用户消息：右对齐蓝色背景 |

##### 页面（7 个 View）

| 页面 | 核心功能 |
|------|---------|
| `LoginView.vue` | 左侧品牌区（深色 + SVG 动画）+ 右侧登录表单 + 蓝紫渐变按钮 `linear-gradient(135deg, #2563EB, #7C3AED)` |
| `DashboardView.vue` | 4 个统计卡片 + 快捷入口（请假/AI/公告）+ 待办列表 + 最近公告 |
| `EmployeeView.vue` | 搜索栏（keyword + 部门 + 状态筛选）+ 表格（手机号脱敏）+ 分页 + 编辑弹窗 |
| `ApprovalView.vue` | 双 Tab："我的申请" + "待我审批"。驳回弹窗**强制填写理由** |
| `AnnouncementView.vue` | 搜索 + 公告卡片列表 + 展开详情 + 发布公告（经理/管理员） |
| `AiChatView.vue` | 左侧对话历史 + 右侧聊天区（欢迎语 + 建议问题 + 流式气泡 + 输入框）。停止生成按钮 |
| `SettingsView.vue` | 用户管理表格 + 角色管理表格（仅 ADMIN 可见） |

---

## 三、数据库表汇总

| # | 表名 | 所属服务 | 说明 |
|---|------|---------|------|
| 1 | `t_employee` | emp-svc | 员工信息（empNo, name, dept, position, phone, email, status） |
| 2 | `t_department` | emp-svc | 部门树（parentId 自关联） |
| 3 | `t_user` | admin-svc | 登录用户（username, password BCrypt） |
| 4 | `t_role` | admin-svc | 角色（ADMIN / MANAGER / EMPLOYEE） |
| 5 | `t_user_role` | admin-svc | 用户-角色关联 |
| 6 | `t_permission` | admin-svc | 权限（emp:view, emp:delete...） |
| 7 | `t_role_permission` | admin-svc | 角色-权限关联 |
| 8 | `t_approval` | admin-svc | ★ 请假审批（leaveType 自由文本，status 状态机） |
| 9 | `t_announcement` | admin-svc | 公告（title, content 富文本） |
| 10 | `t_audit_log` | admin-svc | 操作日志 |

**种子数据**：
- 5 个部门（总公司、技术部、人事部、行政部、财务部）
- 5 名员工（张三、李四、王五、赵六、孙七）
- 3 个用户：`admin/admin`、`manager/admin`、`zhangsan/admin`（密码：`123456`）
- 3 个角色 + 12 条权限 + 角色权限关联
- 2 条公告 + 1 条审批

---

## 四、启动指南

### 4.1 环境要求

| 组件 | 版本 |
|------|------|
| JDK | 21+ |
| Maven | 3.9+ |
| Node.js | 18+ |
| MySQL | 8.0+ |
| Redis | 2.8.9+ |
| Elasticsearch | 7.13.0 |
| Nacos | 1.1.3+ |
| Ollama | latest |

### 4.2 中间件启动顺序

```
1. MySQL     → :3306
2. Redis     → :6379  (redis-cli ping → PONG)
3. ES        → :9200  (curl :9200 → JSON)
4. Nacos     → :8848  (http://localhost:8848/nacos)
5. Ollama    → :11434 (ollama list → qwen2.5:0.5b + nomic-embed-text)
```

### 4.3 后端启动

```bash
# 1. 初始化数据库
mysql -u root -p < D:\OAManagementSystem\sql\init.sql

# 2. 编译公共模块
cd D:\OAManagementSystem\smart-oa-backend
mvn clean install -pl smart-oa-common

# 3. IDEA 中按顺序启动（或 mvn spring-boot:run）：
#    Gateway :8080 → oa-emp-service :8091 → oa-admin-service :8092

# 4. AI 服务（独立 POM，单独启动）
cd D:\OAManagementSystem\smart-oa-backend\oa-ai-service
mvn spring-boot:run    # → :8093
```

### 4.4 前端启动

```bash
cd D:\OAManagementSystem\smart-oa-frontend
npm install
npm run dev             # → http://localhost:5173
```

### 4.5 验证

1. 访问 `http://localhost:5173` → 登录页
2. 用 `admin / 123456` 登录 → 工作台
3. 测试员工搜索 → ES 分词 "技术" 返回技术部
4. 测试请假 → 自由输入类型 "考证" → 提交
5. 测试 AI → 问 "请假需要什么材料？" → 流式回答

---

## 五、关键设计决策

| 决策 | 原因 |
|------|------|
| AI 服务 Boot 3.4.5 独立 | Spring AI 1.0 强制要求 Boot 3.x，不能迁就主工程 Boot 2.7 |
| 请假类型用 `<el-input>` 自由文本 | 非下拉框，适配任意企业场景（年假/考证/远程办公/产检...） |
| ES 同步 try-catch 降级 | ES 不可用时不影响主业务流程 |
| 驳回必填理由 | 强制管理者给出反馈，沟通闭环 |
| 内存向量库（无 RedisStack） | 8GB 电脑即可跑，零额外依赖 |
| 前端代理 `/api` → `:8080` | Vite proxy 解决开发环境跨域 |

---

## 六、端口汇总

| 组件 | 端口 | 说明 |
|------|------|------|
| smart-oa-gateway | 8080 | 统一入口 |
| oa-emp-service | 8091 | 员工服务 |
| oa-admin-service | 8092 | 管理服务 |
| oa-ai-service | 8093 | AI 客服 |
| Vue 前端 (Vite) | 5173 | 开发服务器 |
| MySQL | 3306 | 数据库 |
| Redis | 6379 | 缓存 |
| Elasticsearch | 9200 | 全文检索 |
| Nacos | 8848 | 注册/配置 |
| Ollama | 11434 | 本地大模型 |
