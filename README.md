# School Food Review（今日校园 · 食堂菜单与菜品评价）

基于 HarmonyOS（鸿蒙）ArkTS 开发的校园食堂应用 Demo：浏览食堂菜单、查看菜品详情、发表与查看评价、收藏菜品、切换深色模式。

> 当前版本：**demo0号版本**（演示用 Mock 数据，无后端依赖）

## 功能特性

- **食堂菜单**：多食堂切换，早餐 / 午餐 / 晚餐时段 Tab，档口（窗口）筛选
- **菜品卡片**：菜品图片、价格、评分、招牌/辣/荤标签、售罄标识
- **菜品详情**：营养信息、招牌菜标记、收藏（红心）、点赞评价
- **菜品评价**：星级评分、图文评价、按"最新/最热"排序、分页加载更多（每页 8 条）、图片大图预览
- **我的评价**：评价列表、写评价（相册选图上传）、评价数实时同步
- **我的收藏**：收藏列表，与详情页红心双向同步
- **深色模式**：App 内手动切换开关，主题响应式刷新
- **其他**：骨架屏加载、搜索、下拉刷新、隐私声明页、应用自定义图标

## 技术要点

| 类别 | 说明 |
|---|---|
| 开发环境 | DevEco Studio 5.x，HarmonyOS API 24（compatibleSdkVersion 6.1.1(24)） |
| 语言框架 | ArkTS 严格模式 + ArkUI 声明式 UI |
| 路由体系 | Navigation + NavDestination（pushPathByName 传参） |
| 跨页状态 | AppStorage + @StorageLink 响应式共享（收藏、我的评价、深色模式） |
| 本地存储 | @kit.ArkData Preferences（真机重启恢复兜底） |
| 数据来源 | MockData 静态数据（net/Api 层已预留 USE_MOCK 切换，便于接入真实后端） |
| 深色模式 | ThemeUtil 条件配色（Previewer 兼容） |

## 项目结构

```
entry/src/main/ets/
├── entryability/        # Ability 入口（启动时恢复深色模式偏好）
├── pages/               # 页面：首页 / 菜品详情 / 写评价 / 我的 / 我的评价 / 我的收藏 / 隐私
├── components/          # 组件：DishCard / StarRating / StateView / SkeletonList
├── data/                # MockData 静态数据源
├── model/               # 数据模型（Canteen / Dish / Review / User）
├── net/                 # 网络层（Api 统一入口 + HttpClient，USE_MOCK 分流）
├── utils/               # 工具（PreferencesUtil / CommonUtil / ThemeUtil）
└── config/              # 全局配置常量
```

## 运行方式

1. 使用 DevEco Studio 打开项目根目录
2. 等待工程同步完成（首次会下载 oh_modules 依赖）
3. 直接运行 **Previewer** 预览，或连接 HarmonyOS 真机运行（需在 AppGallery Connect 配置签名）

> 注意：部分能力（如 Preferences 持久化、setColorMode 真机深浅色）在 Previewer 沙箱中不生效，属正常现象，请以真机为准。

## 版本记录

| 版本 | 说明 |
|---|---|
| demo0号版本 | 首个演示版本：菜单/评价/收藏/深色模式等核心功能全部可用（Mock 数据） |

## 后续规划

- 后台管理（CMS）：食堂/菜品/标签增删改、菜品图片上传、售罄状态开关
- 真实后端接入：REST API + 数据库 + 文件上传
- 上架准备：隐私弹窗、应用备案、签名打包
