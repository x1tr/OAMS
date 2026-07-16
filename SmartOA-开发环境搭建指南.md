# SmartOA — 开发环境搭建指南

> **适用对象**：武汉理工大学实训班全体同学 | **平台**：Windows 10/11 x64 | **预计耗时**：2-4小时

---

## 一、环境清单（8个组件）

| # | 组件 | 版本要求 | 端口 | 用途 |
|------|------|------|------|------|
| 1 | JDK | **21+** | — | Java运行环境 |
| 2 | Maven | **3.9+** | — | 项目构建 |
| 3 | MySQL | 8.0+ | 3306 | 业务数据库 |
| 4 | Redis | 2.8.9+ | 6379 | 缓存/Session |
| 5 | Elasticsearch | **7.13.0** | 9200 | 全文检索 |
| 6 | Nacos | 1.1.3+ | 8848 | 服务注册+配置 |
| 7 | Ollama | latest | 11434 | ★ 本地大模型（仅需400MB） |
| 8 | Node.js | 18+ | — | 前端构建 |

> **注意**：RedisStack 不需要安装。AI服务使用**内存向量库**（JDK内置实现），零额外依赖。

---

## 二、安装步骤

### 2.1 JDK 21

```
1. 下载：https://adoptium.net/download/  → 选 JDK 21 LTS, Windows x64
2. 安装到：D:\Develop\Java\jdk-21
3. 配置环境变量：
   系统变量 JAVA_HOME = D:\Develop\Java\jdk-21
   Path 追加 %JAVA_HOME%\bin
4. 验证：java -version  应显示 "21.0.x"
```

### 2.2 Maven 3.9

```
1. 下载：https://maven.apache.org/download.cgi → apache-maven-3.9.9-bin.zip
2. 解压到：D:\Develop\apache-maven-3.9.9
3. 配置环境变量：
   系统变量 MAVEN_HOME = D:\Develop\apache-maven-3.9.9
   Path 追加 %MAVEN_HOME%\bin
4. 编辑 D:\Develop\apache-maven-3.9.9\conf\settings.xml：
   添加阿里云镜像（见下方）
   添加本地仓库路径：<localRepository>D:/Develop/Maven/repository</localRepository>
5. 验证：mvn -version
```

**阿里云镜像配置**（settings.xml 的 `<mirrors>` 中）：

```xml
<mirror>
    <id>aliyun</id>
    <url>https://maven.aliyun.com/repository/public</url>
    <mirrorOf>central</mirrorOf>
</mirror>
```

### 2.3 MySQL 8.0

```
推荐方式：Docker Desktop
  docker run -d --name mysql-oa -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=root123 \
    mysql:8.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

免安装方式：
  下载 ZIP → 解压到 D:\Develop\mysql-8.0 → 创建 my.ini → mysqld --initialize
```

**my.ini 关键配置**：
```ini
[mysqld]
port=3306
basedir=D:/Develop/mysql-8.0
datadir=D:/Develop/mysql-8.0/data
character-set-server=utf8mb4
innodb_buffer_pool_size=256M
```

### 2.4 Redis

```
推荐方式：Docker Desktop
  docker run -d --name redis-oa -p 6379:6379 redis:7-alpine

备选方式：Memurai（Windows原生Redis兼容）
  https://www.memurai.com/get-memurai → 安装Developer版（免费）
```

验证：`redis-cli ping` → 返回 PONG

### 2.5 RedisStack（不需要安装）

**oa-ai-service 默认使用内存向量库，无需 RedisStack。**

AI服务启动时自动从本地文件加载知识库文档 → Ollama向量化 → 存入内存HashMap → 运行时纯内存检索。

如果未来需要扩展为生产级，只需改一行配置：
```yaml
ai.assistant.vector-mode: redis   # 从 memory 改为 redis
```

### 2.6 Elasticsearch 7.13.0

```
1. 下载：https://www.elastic.co/cn/downloads/past-releases/elasticsearch-7-13-0
2. 解压到：D:\Develop\elasticsearch-7.13.0
3. 修改 config/elasticsearch.yml：
   discovery.type: single-node
   network.host: 0.0.0.0
   xpack.security.enabled: false
4. 修改 config/jvm.options（降低内存占用）：
   -Xms512m
   -Xmx512m
5. 安装 IK 中文分词器：
   bin\elasticsearch-plugin install ^
     https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.13.0/elasticsearch-analysis-ik-7.13.0.zip
6. 启动：bin\elasticsearch.bat
7. 验证：http://localhost:9200 → JSON返回
```

**常见启动失败**：
- JVM内存超过系统可用 → 降低 jvm.options 的 -Xmx
- 杀毒软件拦截 → 添加ES目录到排除列表
- 端口占用 → `netstat -ano | findstr 9200`

### 2.7 Nacos

```
1. 下载：https://github.com/alibaba/nacos/releases → 2.3.2 版本
2. 解压到：D:\Develop\nacos
3. 启动（单机模式）：
   bin\startup.cmd -m standalone
4. 控制台：http://localhost:8848/nacos
   账号/密码：nacos / nacos
```

### 2.8 Ollama

```
1. 下载安装：https://ollama.com/download/windows （安装后自动后台运行）
2. 打开CMD，拉取模型（仅需两个，共约700MB）：
   ollama pull qwen2.5:0.5b         约400MB，对话模型（轻量版，8GB内存可跑）
   ollama pull nomic-embed-text      约274MB，向量化模型
3. 验证：
   ollama list                       应显示两个模型
   ollama run qwen2.5:0.5b          输入"你好"测试对话
```

**注意**：实训统一使用 qwen2.5:0.5b（约400MB），8GB内存即可。

### 2.9 Node.js

```
1. 下载：https://nodejs.org/ → 推荐 20.x LTS
2. 验证：node -v  npm -v
3. 加速：npm config set registry https://registry.npmmirror.com
```

---

## 三、项目启动

### 3.1 中间件启动顺序

```
Step 1: MySQL     → 确认端口 3306 可连接
Step 2: Redis     → redis-cli ping
Step 3: ES        → http://localhost:9200
Step 4: Nacos     → http://localhost:8848/nacos
Step 5: Ollama    → ollama list 确认模型已拉取
```

验证命令一行跑：
```bash
redis-cli ping && curl localhost:9200 && curl localhost:8848/nacos && ollama list
```

### 3.2 微服务启动（IDEA中按顺序）

```
1. Gateway           → Port 8080   (先启动，其他服务注册到Nacos)
2. oa-emp-service    → Port 8091
3. oa-admin-service  → Port 8092
4. oa-ai-service     → Port 8093
```

检查 Nacos 控制台 → 服务管理 → 四个服务均为"健康"状态。

### 3.3 前端启动

```bash
cd smart-oa-frontend
npm install
npm run dev       # → http://localhost:5173
```

### 3.4 创建数据库

```sql
CREATE DATABASE smart_oa DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- 然后执行项目中的建表SQL脚本
```

---

## 四、常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| ES闪退 | 内存不足 | jvm.options 降低 -Xmx 到 512m |
| Nacos启动闪退 | 没加 `-m standalone` | 用命令 `startup.cmd -m standalone` |
| Maven下载慢 | 没用国内镜像 | settings.xml 加阿里云mirror |
| Ollama下载慢 | 网络问题 | 同学间复制 `C:\Users\<用户名>\.ollama\` 目录 |
| 端口冲突 | 其他程序占用 | `netstat -ano \| findstr "端口号"` → `taskkill /PID xxx /F` |
| npm install失败 | node-gyp问题 | `npm cache clean --force` 后重试 |
| RedisStack装不了 | 无Docker | AI服务设 `vector-mode: memory` |

---

## 五、D盘目录建议

```
D:\
├── Develop\
│   ├── Java\jdk-21\
│   ├── apache-maven-3.9.9\
│   ├── Maven\repository\         (Maven本地仓库)
│   ├── mysql-8.0\
│   ├── nacos\
│   ├── elasticsearch-7.13.0\
│   └── workspace\smart-oa\       (项目代码)
├── OAManagementSystem\           (项目文档)
│   ├── SmartOA-项目视图与范围文档.md
│   ├── SmartOA-系统架构设计文档.md
│   ├── SmartOA-前端设计规范.md
│   └── SmartOA-开发环境搭建指南.md
└── Docker\                       (Docker数据)
```

---

## 六、环境变量速查

| 变量名 | 值 | 用途 |
|--------|-----|------|
| `JAVA_HOME` | `D:\Develop\Java\jdk-21` | JDK |
| `MAVEN_HOME` | `D:\Develop\apache-maven-3.9.9` | Maven |
| Path新增 | `%JAVA_HOME%\bin` `%MAVEN_HOME%\bin` | 命令行可用 |

---

> **提前准备**：建议实训开始前至少**提前1天**完成以上所有安装。遇到问题截图+错误信息发群，不要卡住自己。Docker能装尽量装，装不了也有降级方案，不影响项目开发。
