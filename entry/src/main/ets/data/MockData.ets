import { Canteen, Stall } from '../model/Canteen';
import { Dish, MealType, Nutrition } from '../model/Dish';
import { MyReviewItem, Review, ReviewDimensions, ReviewPage, ReviewSortType, ReviewStatus, WriteReviewParam } from '../model/Review';
import { User } from '../model/User';
import { AppConfig } from '../config/AppConfig';
import { generateUuid } from '../utils/CommonUtil';
import { PreferencesUtil } from '../utils/PreferencesUtil';

export class MockData {
  private static delay<T>(data: T, ms: number = 300): Promise<T> {
    return new Promise<T>((resolve) => setTimeout(() => resolve(data), ms));
  }

  private static canteens: Canteen[] = [
    new Canteen('c1', '第一食堂', '校园东区', '06:30-21:00', 3, ''),
    new Canteen('c2', '第二食堂', '校园西区', '06:30-21:00', 2, ''),
    new Canteen('c3', '清真食堂', '校园北区', '06:30-20:00', 1, '')
  ];

  static getCanteenList(): Promise<Canteen[]> {
    return MockData.delay(MockData.canteens.slice());
  }

  static getStallList(canteenId: string): Promise<Stall[]> {
    const stalls: Stall[] = [
      new Stall('s1', canteenId, '川菜窗口', 2, '川菜', ''),
      new Stall('s2', canteenId, '面食窗口', 1, '面食', ''),
      new Stall('s3', canteenId, '盖浇饭窗口', 2, '快餐', '')
    ];
    return MockData.delay(stalls);
  }

  private static dishes: Dish[] = MockData.buildDishes();

  private static buildDishes(): Dish[] {
    const list: Dish[] = [];
    const d1 = new Dish();
    d1.id = 'd1'; d1.stallId = 's1'; d1.canteenId = 'c1'; d1.name = '宫保鸡丁';
    d1.price = 12.5; d1.tags = ['招牌', '辣', '荤'];
    d1.stallName = '川菜窗口'; d1.canteenName = '第一食堂'; d1.floor = 2;
    d1.rating = 4.6; d1.reviewCount = 128; d1.isSignature = true; d1.soldOut = false;
    d1.nutrition = new Nutrition(520, false, ['花生']);
    d1.image = 'dish_1.png';
    list.push(d1);

    const d2 = new Dish();
    d2.id = 'd2'; d2.stallId = 's1'; d2.canteenId = 'c1'; d2.name = '麻婆豆腐';
    d2.price = 9.0; d2.tags = ['辣', '素'];
    d2.stallName = '川菜窗口'; d2.canteenName = '第一食堂'; d2.floor = 2;
    d2.rating = 4.3; d2.reviewCount = 86; d2.isSignature = false; d2.soldOut = false;
    d2.nutrition = new Nutrition(380, true, []);
    d2.image = 'dish_2.png';
    list.push(d2);

    const d3 = new Dish();
    d3.id = 'd3'; d3.stallId = 's2'; d3.canteenId = 'c1'; d3.name = '兰州牛肉面';
    d3.price = 15.0; d3.tags = ['招牌', '清真'];
    d3.stallName = '面食窗口'; d3.canteenName = '第一食堂'; d3.floor = 1;
    d3.rating = 4.8; d3.reviewCount = 256; d3.isSignature = true; d3.soldOut = false;
    d3.nutrition = new Nutrition(620, false, ['麸质']);
    d3.image = 'dish_3.png';
    list.push(d3);

    const d4 = new Dish();
    d4.id = 'd4'; d4.stallId = 's3'; d4.canteenId = 'c1'; d4.name = '番茄炒蛋盖饭';
    d4.price = 11.0; d4.tags = ['家常'];
    d4.stallName = '盖浇饭窗口'; d4.canteenName = '第一食堂'; d4.floor = 2;
    d4.rating = 4.1; d4.reviewCount = 64; d4.isSignature = false; d4.soldOut = true;
    d4.nutrition = new Nutrition(560, false, []);
    d4.image = 'dish_4.png';
    list.push(d4);

    const d5 = new Dish();
    d5.id = 'd5'; d5.stallId = 's1'; d5.canteenId = 'c2'; d5.name = '回锅肉';
    d5.price = 14.0; d5.tags = ['荤', '辣'];
    d5.stallName = '川菜窗口'; d5.canteenName = '第二食堂'; d5.floor = 2;
    d5.rating = 4.5; d5.reviewCount = 102; d5.isSignature = true; d5.soldOut = false;
    d5.nutrition = new Nutrition(600, false, []);
    d5.image = 'dish_5.png';
    list.push(d5);

    const d6 = new Dish();
    d6.id = 'd6'; d6.stallId = 's2'; d6.canteenId = 'c2'; d6.name = '阳春面';
    d6.price = 8.0; d6.tags = ['素', '清淡'];
    d6.stallName = '面食窗口'; d6.canteenName = '第二食堂'; d6.floor = 1;
    d6.rating = 4.0; d6.reviewCount = 48; d6.isSignature = false; d6.soldOut = false;
    d6.nutrition = new Nutrition(420, true, ['麸质']);
    d6.image = 'dish_6.png';
    list.push(d6);

    return list;
  }

  static getTodayMenu(canteenId: string, mealType: MealType): Promise<Dish[]> {
    let list = MockData.dishes.filter((d: Dish) => d.canteenId === canteenId);
    if (mealType === MealType.BREAKFAST) list = list.slice(0, 2);
    return MockData.delay(list);
  }

  static searchDishes(keyword: string): Promise<Dish[]> {
    const kw = keyword.trim();
    if (!kw) return MockData.delay(MockData.dishes.slice());
    const list = MockData.dishes.filter((d: Dish) => d.name.includes(kw) || d.tags.includes(kw));
    return MockData.delay(list);
  }

  static getDishDetail(dishId: string): Promise<Dish> {
    const d = MockData.dishes.find((x: Dish) => x.id === dishId) ?? MockData.dishes[0];
    return MockData.delay(d);
  }

  private static reviews: Review[] = MockData.buildReviews();

  private static buildReviews(): Review[] {
    const list: Review[] = [];
    const r1 = new Review();
    r1.id = 'r1'; r1.dishId = 'd1'; r1.userId = 'u1'; r1.userNickname = '小张';
    r1.rating = 5; r1.dimensions = new ReviewDimensions(5, 4, 5);
    r1.content = '味道很正宗，花生酥脆，鸡肉嫩滑，性价比高！';
    r1.likes = 12; r1.isAnonymous = false; r1.status = ReviewStatus.APPROVED;
    r1.createTime = '2026-09-23T12:30:00';
    list.push(r1);

    const r2 = new Review();
    r2.id = 'r2'; r2.dishId = 'd1'; r2.userId = 'u2'; r2.userNickname = '匿名同学';
    r2.rating = 4; r2.dimensions = new ReviewDimensions(4, 5, 4);
    r2.content = '分量很足，口味偏辣，配米饭很合适。';
    r2.likes = 5; r2.isAnonymous = true; r2.status = ReviewStatus.APPROVED;
    r2.createTime = '2026-09-22T18:10:00';
    list.push(r2);

    // d1 额外测试评价（r4~r10），用于演示“加载更多”分页
    const r4 = new Review();
    r4.id = 'r4'; r4.dishId = 'd1'; r4.userId = 'u4'; r4.userNickname = '干饭第一名';
    r4.rating = 5; r4.dimensions = new ReviewDimensions(5, 5, 5);
    r4.content = '每周必点！辣度刚好，下饭神器。';
    r4.likes = 21; r4.isAnonymous = false; r4.status = ReviewStatus.APPROVED;
    r4.createTime = '2026-09-21T12:05:00';
    list.push(r4);

    const r5 = new Review();
    r5.id = 'r5'; r5.dishId = 'd1'; r5.userId = 'u5'; r5.userNickname = '匿名同学';
    r5.rating = 3; r5.dimensions = new ReviewDimensions(3, 4, 3);
    r5.content = '今天花生有点少，味道还行吧。';
    r5.likes = 3; r5.isAnonymous = true; r5.status = ReviewStatus.APPROVED;
    r5.createTime = '2026-09-20T18:40:00';
    list.push(r5);

    const r6 = new Review();
    r6.id = 'r6'; r6.dishId = 'd1'; r6.userId = 'u6'; r6.userNickname = '体育部的浩哥';
    r6.rating = 4; r6.dimensions = new ReviewDimensions(4, 4, 4);
    r6.content = '训练完来一份，很顶饱，就是排队有点久。';
    r6.likes = 9; r6.isAnonymous = false; r6.status = ReviewStatus.APPROVED;
    r6.createTime = '2026-09-19T12:20:00';
    list.push(r6);

    const r7 = new Review();
    r7.id = 'r7'; r7.dishId = 'd1'; r7.userId = 'u7'; r7.userNickname = '爱吃辣的小王';
    r7.rating = 2; r7.dimensions = new ReviewDimensions(2, 3, 2);
    r7.content = '感觉不如上学期好吃，鸡肉有点柴。';
    r7.likes = 1; r7.isAnonymous = false; r7.status = ReviewStatus.APPROVED;
    r7.createTime = '2026-09-18T18:30:00';
    list.push(r7);

    const r8 = new Review();
    r8.id = 'r8'; r8.dishId = 'd1'; r8.userId = 'u8'; r8.userNickname = '匿名同学';
    r8.rating = 4; r8.dimensions = new ReviewDimensions(4, 5, 3);
    r8.content = '性价比可以，能再多点鸡肉就更好了。';
    r8.likes = 6; r8.isAnonymous = true; r8.status = ReviewStatus.APPROVED;
    r8.createTime = '2026-09-17T12:15:00';
    list.push(r8);

    const r9 = new Review();
    r9.id = 'r9'; r9.dishId = 'd1'; r9.userId = 'u9'; r9.userNickname = '奶茶续命中';
    r9.rating = 5; r9.dimensions = new ReviewDimensions(5, 5, 4);
    r9.content = '阿姨手不抖，花生米超香，回购第三次了！';
    r9.likes = 15; r9.isAnonymous = false; r9.status = ReviewStatus.APPROVED;
    r9.createTime = '2026-09-16T11:50:00';
    list.push(r9);

    const r10 = new Review();
    r10.id = 'r10'; r10.dishId = 'd1'; r10.userId = 'u10'; r10.userNickname = '深夜学习人';
    r10.rating = 3; r10.dimensions = new ReviewDimensions(3, 3, 4);
    r10.content = '中规中矩，适合不知道吃什么的时候选。';
    r10.likes = 2; r10.isAnonymous = false; r10.status = ReviewStatus.APPROVED;
    r10.createTime = '2026-09-15T18:25:00';
    list.push(r10);

    // d1 第二批测试评价（r11~r18），保证页大小为 8 时“加载更多”能刷出整页
    const r11 = new Review();
    r11.id = 'r11'; r11.dishId = 'd1'; r11.userId = 'u11'; r11.userNickname = '图书馆常驻民';
    r11.rating = 4; r11.dimensions = new ReviewDimensions(4, 4, 4);
    r11.content = '复习间隙来一份，熟悉的味道，稳定发挥。';
    r11.likes = 11; r11.isAnonymous = false; r11.status = ReviewStatus.APPROVED;
    r11.createTime = '2026-09-14T12:10:00';
    list.push(r11);

    const r12 = new Review();
    r12.id = 'r12'; r12.dishId = 'd1'; r12.userId = 'u12'; r12.userNickname = '匿名同学';
    r12.rating = 5; r12.dimensions = new ReviewDimensions(5, 5, 5);
    r12.content = '新品辣度升级版绝了，越吃越上头！';
    r12.likes = 8; r12.isAnonymous = true; r12.status = ReviewStatus.APPROVED;
    r12.createTime = '2026-09-13T18:20:00';
    list.push(r12);

    const r13 = new Review();
    r13.id = 'r13'; r13.dishId = 'd1'; r13.userId = 'u13'; r13.userNickname = '大一萌新';
    r13.rating = 3; r13.dimensions = new ReviewDimensions(3, 4, 3);
    r13.content = '第一次吃，稍微有点咸，总体还可以。';
    r13.likes = 4; r13.isAnonymous = false; r13.status = ReviewStatus.APPROVED;
    r13.createTime = '2026-09-12T12:00:00';
    list.push(r13);

    const r14 = new Review();
    r14.id = 'r14'; r14.dishId = 'd1'; r14.userId = 'u14'; r14.userNickname = '篮球场常客';
    r14.rating = 4; r14.dimensions = new ReviewDimensions(4, 5, 3);
    r14.content = '打完球吃这个很舒服，建议加个卤蛋。';
    r14.likes = 7; r14.isAnonymous = false; r14.status = ReviewStatus.APPROVED;
    r14.createTime = '2026-09-11T18:35:00';
    list.push(r14);

    const r15 = new Review();
    r15.id = 'r15'; r15.dishId = 'd1'; r15.userId = 'u15'; r15.userNickname = '匿名同学';
    r15.rating = 2; r15.dimensions = new ReviewDimensions(2, 2, 3);
    r15.content = '那天可能是快打烊了，菜是凉的，体验不好。';
    r15.likes = 2; r15.isAnonymous = true; r15.status = ReviewStatus.APPROVED;
    r15.createTime = '2026-09-10T12:25:00';
    list.push(r15);

    const r16 = new Review();
    r16.id = 'r16'; r16.dishId = 'd1'; r16.userId = 'u16'; r16.userNickname = '考研上岸人';
    r16.rating = 5; r16.dimensions = new ReviewDimensions(5, 5, 5);
    r16.content = '吃了大半年，从没失望过，陪着我和研友上岸！';
    r16.likes = 18; r16.isAnonymous = false; r16.status = ReviewStatus.APPROVED;
    r16.createTime = '2026-09-09T11:55:00';
    list.push(r16);

    const r17 = new Review();
    r17.id = 'r17'; r17.dishId = 'd1'; r17.userId = 'u17'; r17.userNickname = '寝室长本长';
    r17.rating = 4; r17.dimensions = new ReviewDimensions(4, 4, 4);
    r17.content = '帮全寝室带过好几次，出餐快，不易洒。';
    r17.likes = 5; r17.isAnonymous = false; r17.status = ReviewStatus.APPROVED;
    r17.createTime = '2026-09-08T18:15:00';
    list.push(r17);

    const r18 = new Review();
    r18.id = 'r18'; r18.dishId = 'd1'; r18.userId = 'u18'; r18.userNickname = '干饭小分队';
    r18.rating = 3; r18.dimensions = new ReviewDimensions(3, 3, 3);
    r18.content = '中规中矩的家常味，胜在分量足。';
    r18.likes = 3; r18.isAnonymous = false; r18.status = ReviewStatus.APPROVED;
    r18.createTime = '2026-09-07T12:40:00';
    list.push(r18);

    const r3 = new Review();
    r3.id = 'r3'; r3.dishId = 'd3'; r3.userId = 'u3'; r3.userNickname = '面食爱好者';
    r3.rating = 5; r3.dimensions = new ReviewDimensions(5, 5, 5);
    r3.content = '牛肉给得很足，汤头浓郁，强烈推荐！';
    r3.likes = 28; r3.isAnonymous = false; r3.status = ReviewStatus.APPROVED;
    r3.createTime = '2026-09-24T11:45:00';
    list.push(r3);

    return list;
  }

  static getReviews(dishId: string, page: number, sort: ReviewSortType): Promise<ReviewPage> {
    let list = MockData.reviews.filter((r: Review) => r.dishId === dishId && r.status === ReviewStatus.APPROVED);
    if (sort === ReviewSortType.HOTTEST) {
      list = list.slice().sort((a: Review, b: Review): number => b.likes - a.likes);
    } else {
      list = list.slice().sort((a: Review, b: Review): number =>
        new Date(b.createTime).getTime() - new Date(a.createTime).getTime());
    }
    const start = (page - 1) * AppConfig.REVIEW_PAGE_SIZE;
    const pageList = list.slice(start, start + AppConfig.REVIEW_PAGE_SIZE);
    const pageData: ReviewPage = {
      list: pageList,
      total: list.length,
      page: page,
      pageSize: AppConfig.REVIEW_PAGE_SIZE,
      hasMore: start + pageList.length < list.length
    };
    return MockData.delay(pageData);
  }

  /** 本地用户发布的评价（附菜品名），用于“我的评价”列表 */
  private static myReviewsLoaded: boolean = false;

  static async getMyReviews(): Promise<MyReviewItem[]> {
    if (!MockData.myReviewsLoaded) {
      MockData.myReviewsLoaded = true;
      // 重启/重新预览后从本地存储恢复已发布的评价
      const saved: Review[] | null = await PreferencesUtil.getObject<Review[]>(AppConfig.PREF_KEY_MY_REVIEWS);
      if (saved) {
        for (const r of saved) {
          const exists = MockData.reviews.some((x: Review): boolean => x.id === r.id);
          if (!exists) MockData.reviews.unshift(r);
        }
      }
    }
    const list: MyReviewItem[] = MockData.syncMyReviewsToAppStorage();
    return MockData.delay(list);
  }

  /** 同步本地用户评价到 AppStorage，供“我的”相关页面实时刷新 */
  private static syncMyReviewsToAppStorage(): MyReviewItem[] {
    const list: MyReviewItem[] = [];
    for (const r of MockData.reviews) {
      if (r.userId === 'local') {
        const dish = MockData.dishes.find((d: Dish) => d.id === r.dishId);
        list.push(new MyReviewItem(r, dish ? dish.name : '未知菜品'));
      }
    }
    AppStorage.setOrCreate<MyReviewItem[]>('myReviews', list);
    AppStorage.setOrCreate<number>('myReviewCount', list.length);
    return list;
  }

  /** 持久化本地用户发布的评价列表 */
  private static async persistMyReviews(): Promise<void> {
    const mine: Review[] = [];
    for (const r of MockData.reviews) {
      if (r.userId === 'local') mine.push(r);
    }
    await PreferencesUtil.putObject(AppConfig.PREF_KEY_MY_REVIEWS, mine);
  }

  static async submitReview(req: WriteReviewParam): Promise<Review> {
    const review = new Review();
    review.id = 'r' + Date.now();
    review.dishId = req.dishId;
    review.userId = 'local';
    review.userNickname = '我';
    review.rating = req.rating;
    review.dimensions = req.dimensions;
    review.content = req.content;
    review.images = req.images;
    review.likes = 0;
    review.isAnonymous = req.isAnonymous;
    review.status = ReviewStatus.APPROVED;
    review.createTime = new Date().toISOString();
    MockData.reviews.unshift(review);
    await MockData.persistMyReviews();
    MockData.syncMyReviewsToAppStorage();
    return MockData.delay(review);
  }

  private static likedReviewIds: string[] = [];

  /** 点赞/取消点赞，返回最新点赞数 */
  static likeReview(reviewId: string): number {
    const r = MockData.reviews.find((x: Review) => x.id === reviewId);
    if (!r) return 0;
    const idx = MockData.likedReviewIds.indexOf(reviewId);
    if (idx >= 0) {
      MockData.likedReviewIds.splice(idx, 1);
      r.likes -= 1;
    } else {
      MockData.likedReviewIds.push(reviewId);
      r.likes += 1;
    }
    return r.likes;
  }

  private static localUser: User = new User(
    generateUuid(),
    '同学' + Math.floor(Math.random() * 1000),
    '',
    []
  );

  static getLocalUser(): Promise<User> {
    return MockData.delay(new User(
      MockData.localUser.id,
      MockData.localUser.nickname,
      MockData.localUser.avatar,
      MockData.localUser.favorites.slice()
    ));
  }

  /** 收藏列表唯一数据源；首次访问时从本地存储播种（兼容真机重启恢复） */
  private static favoritesLoaded: boolean = false;

  static async getFavorites(): Promise<string[]> {
    if (!MockData.favoritesLoaded) {
      MockData.favoritesLoaded = true;
      const saved: string[] = await PreferencesUtil.getFavorites();
      if (saved.length > 0 && MockData.localUser.favorites.length === 0) {
        MockData.localUser.favorites = saved;
      }
    }
    AppStorage.setOrCreate<string[]>('favorites', MockData.localUser.favorites.slice());
    return MockData.localUser.favorites.slice();
  }

  /** 已收藏的菜品列表（按收藏顺序） */
  static getFavoriteDishes(): Promise<Dish[]> {
    const list: Dish[] = MockData.dishes.filter((d: Dish): boolean =>
      MockData.localUser.favorites.includes(d.id));
    return MockData.delay(list);
  }

  static toggleFavorite(dishId: string): Promise<string[]> {
    const idx = MockData.localUser.favorites.indexOf(dishId);
    if (idx >= 0) {
      MockData.localUser.favorites.splice(idx, 1);
    } else {
      MockData.localUser.favorites.push(dishId);
    }
    AppStorage.setOrCreate<string[]>('favorites', MockData.localUser.favorites.slice());
    return MockData.delay(MockData.localUser.favorites.slice());
  }
}
