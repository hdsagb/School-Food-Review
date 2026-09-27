# School Food Review（校园食评 · 食堂菜单与菜品评价）

基于 HarmonyOS（鸿蒙）ArkTS 开发的校园食堂应用 Demo：浏览食堂菜单、查看菜品详情、发表与查看评价、收藏菜品、切换深色模式。配套 Node.js + Express + SQLite 真实后端与网页管理后台。

> 当前版本：**v1.0（demo1号版本）** —— 真实后端接入，App 数据全部来自 REST API；另有网页管理端可维护食堂/档口/菜品/评价审核

## 功能特性

- **食堂菜单**：多食堂切换，早餐 / 午餐 / 晚餐时段 Tab，档口（窗口）筛选
- **菜品卡片**：菜品图片、价格、评分、招牌/辣/荤标签、售罄标识
- **菜品详情**：营养信息、招牌菜标记、收藏（红心）、点赞评价
- **菜品评价**：星级评分、图文评价、按"最新/最热"排序、分页加载更多（每页 8 条）、图片大图预览
- **我的评价**：评价列表、写评价（相册选图上传到服务器）、评价数实时同步
- **我的收藏**：收藏列表，与详情页红心双向同步
- **深色模式**：App 内手动切换开关，主题响应式刷新
- **管理后台（网页）**：管理员登录，食堂/档口/菜品增删改、售罄开关、菜品图片上传、评价审核
- **其他**：骨架屏加载、搜索、下拉刷新、隐私声明页、应用自定义图标

## 技术要点

| 类别 | 说明 |
|---|---|
| 开发环境 | DevEco Studio 5.x，HarmonyOS API 24（compatibleSdkVersion 6.1.1(24)） |
| 语言框架 | ArkTS 严格模式 + ArkUI 声明式 UI |
| 路由体系 | Navigation + NavDestination（pushPathByName 传参） |
| 跨页状态 | AppStorage + @StorageLink 响应式共享（收藏、我的评价、深色模式） |
| 本地存储 | @kit.ArkData Preferences（token、用户信息、深色模式、点赞记录持久化） |
| 网络层 | net/HttpClient 统一封装（Bearer 鉴权、x-auth-token 捕获、multipart 上传），net/Api 业务接口（USE_MOCK 开关） |
| 后端 | Node.js 24 + Express 4 + SQLite（node:sqlite，零原生依赖）、bcryptjs 密码哈希、multer 图片上传 |
| 鉴权 | 游客无感建号：首次访问服务端下发 X-Auth-Token，客户端捕获持久化；管理端独立账号会话 |
| 深色模式 | ThemeUtil 条件配色（Previewer 兼容） |

## 项目结构

```
├── entry/src/main/ets/        # HarmonyOS App 端
│   ├── entryability/          # Ability 入口（启动时恢复深色模式偏好）
│   ├── pages/                 # 页面：首页 / 菜品详情 / 写评价 / 我的 / 我的评价 / 我的收藏 / 隐私
│   ├── components/            # 组件：DishCard / StarRating / StateView / TopBar / LoadMoreFooter ...
│   ├── data/                  # MockData 静态数据源（USE_MOCK 兜底）
│   ├── model/                 # 数据模型（Canteen / Dish / Review / User）
│   ├── net/                   # 网络层（Api 统一入口 + HttpClient，USE_MOCK 分流）
│   ├── utils/                 # 工具（PreferencesUtil / CommonUtil / ThemeUtil）
│   └── config/                # AppConfig（API_BASE_URL / USE_MOCK 等）
└── server/                    # Node.js 后端 + 网页管理端
    ├── index.js               # Express 入口（/api /api/admin /api/upload + 静态资源）
    ├── db.js                  # SQLite 建表 + 种子数据（3 食堂 / 6 档口 / 6 菜品 / 18 评价）
    ├── auth.js                # Bearer 解析 / token 签发 / 游客-管理员鉴权
    ├── routes/                # client（App 接口）/ admin（管理接口）/ upload（图片上传）
    └── public/                # 网页管理后台（原生 JS 单页，零构建）
```

## 运行方式

### 1. 启动后端（Node.js ≥ 24）

```bash
cd server
npm install      # 首次执行
npm start        # 默认端口 3000，首次启动自动建表并播种演示数据
```

- App 接口地址：`http://<host>:3000/api`（模拟器访问宿主机用 `10.0.2.2`）
- 网页管理端：浏览器打开 `http://<host>:3000`，默认账号 `admin / admin123`
- 数据落在 `server/data.db`，上传图片在 `server/uploads/`（均已被 .gitignore 忽略）

### 2. 运行 App

1. 使用 DevEco Studio 打开项目根目录
2. 确认 `entry/src/main/ets/config/AppConfig.ets` 中 `API_BASE_URL` 指向后端地址（模拟器 `10.0.2.2`，真机改为电脑局域网 IP），`USE_MOCK = false`
3. 连接 HarmonyOS 真机运行（需在 AppGallery Connect 配置签名）；Previewer 沙箱不支持网络请求，仅可用于 UI 预览

> 无后端环境时可将 `USE_MOCK` 置为 `true`，App 回退到 MockData 演示数据。

## 版本记录

| 版本 | 说明 |
|---|---|
| demo0号版本 | 首个演示版本：菜单/评价/收藏/深色模式等核心功能全部可用（Mock 数据） |
| v1.0（demo1号版本） | 接入真实后端：REST API + SQLite 数据库 + 图片上传 + 网页管理后台（食堂/档口/菜品维护、售罄开关、评价审核），游客无感建号鉴权 |

## 后续规划

- 上架准备：隐私弹窗、应用备案、签名打包
- 管理端增强：标签管理、数据统计、图片管理
- 搜索 / 推荐算法优化
