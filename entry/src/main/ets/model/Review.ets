/**
 * 评价三维度评分
 */
export class ReviewDimensions {
  taste: number;
  portion: number;
  value: number;

  constructor(taste: number = 5, portion: number = 5, value: number = 5) {
    this.taste = taste;
    this.portion = portion;
    this.value = value;
  }
}

/**
 * 评价数据模型（class 形式）
 */
export class Review {
  id: string;
  dishId: string;
  userId: string;
  userNickname: string;
  userAvatar: string;
  rating: number;
  dimensions: ReviewDimensions;
  content: string;
  images: string[];
  likes: number;
  isAnonymous: boolean;
  status: ReviewStatus;
  createTime: string;

  constructor() {
    this.id = '';
    this.dishId = '';
    this.userId = '';
    this.userNickname = '';
    this.userAvatar = '';
    this.rating = 5;
    this.dimensions = new ReviewDimensions();
    this.content = '';
    this.images = [];
    this.likes = 0;
    this.isAnonymous = false;
    this.status = ReviewStatus.APPROVED;
    this.createTime = '';
  }
}

/**
 * 评价状态
 */
export enum ReviewStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected'
}

/**
 * 评价排序方式
 */
export enum ReviewSortType {
  LATEST = 'latest',
  HOTTEST = 'hottest'
}

/**
 * 评价分页数据
 */
export interface ReviewPage {
  list: Review[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

/**
 * 提交评价请求参数
 */
export interface WriteReviewParam {
  dishId: string;
  rating: number;
  dimensions: ReviewDimensions;
  content: string;
  images: string[];
  isAnonymous: boolean;
}

/**
 * 我的评价列表项（评价 + 所属菜品名）
 */
export class MyReviewItem {
  review: Review;
  dishName: string;

  constructor(review: Review, dishName: string) {
    this.review = review;
    this.dishName = dishName;
  }
}
