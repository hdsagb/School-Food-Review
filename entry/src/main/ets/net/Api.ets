import { HttpClient } from './HttpClient';
import { AppConfig } from '../config/AppConfig';
import { User } from '../model/User';
import { Canteen, Stall } from '../model/Canteen';
import { Dish, MealType } from '../model/Dish';
import { MyReviewItem, Review, ReviewPage, ReviewSortType, WriteReviewParam } from '../model/Review';
import { MockData } from '../data/MockData';

export class Api {
  private static client: HttpClient = HttpClient.getInstance();

  static async getCanteenList(): Promise<Canteen[]> {
    if (AppConfig.USE_MOCK) return MockData.getCanteenList();
    return Api.client.get<Canteen[]>('/canteens');
  }

  static async getStallList(canteenId: string): Promise<Stall[]> {
    if (AppConfig.USE_MOCK) return MockData.getStallList(canteenId);
    return Api.client.get<Stall[]>(`/canteens/${canteenId}/stalls`);
  }

  static async getTodayMenu(canteenId: string, mealType: MealType): Promise<Dish[]> {
    if (AppConfig.USE_MOCK) return MockData.getTodayMenu(canteenId, mealType);
    const params: Record<string, string> = { 'canteenId': canteenId, 'mealType': mealType };
    return Api.client.get<Dish[]>('/menu/today', params);
  }

  static async searchDishes(keyword: string): Promise<Dish[]> {
    if (AppConfig.USE_MOCK) return MockData.searchDishes(keyword);
    const params: Record<string, string> = { 'keyword': keyword };
    return Api.client.get<Dish[]>('/dishes/search', params);
  }

  static async getDishDetail(dishId: string): Promise<Dish> {
    if (AppConfig.USE_MOCK) return MockData.getDishDetail(dishId);
    return Api.client.get<Dish>(`/dishes/${dishId}`);
  }

  static async getReviews(
    dishId: string,
    page: number,
    sort: ReviewSortType
  ): Promise<ReviewPage> {
    if (AppConfig.USE_MOCK) return MockData.getReviews(dishId, page, sort);
    const params: Record<string, string> = {
      'page': String(page),
      'pageSize': String(AppConfig.REVIEW_PAGE_SIZE),
      'sort': sort
    };
    return Api.client.get<ReviewPage>(`/dishes/${dishId}/reviews`, params);
  }

  static async submitReview(req: WriteReviewParam): Promise<Review> {
    if (AppConfig.USE_MOCK) return MockData.submitReview(req);
    return Api.client.post<Review>('/reviews', req);
  }

  static async likeReview(reviewId: string): Promise<number> {
    if (AppConfig.USE_MOCK) return MockData.likeReview(reviewId);
    return Api.client.post<number>(`/reviews/${reviewId}/like`);
  }

  static async getMyReviews(): Promise<MyReviewItem[]> {
    if (AppConfig.USE_MOCK) return MockData.getMyReviews();
    const list = await Api.client.get<MyReviewItem[]>('/user/reviews');
    AppStorage.setOrCreate<MyReviewItem[]>('myReviews', list);
    AppStorage.setOrCreate<number>('myReviewCount', list.length);
    return list;
  }

  static async getLocalUser(): Promise<User> {
    if (AppConfig.USE_MOCK) return MockData.getLocalUser();
    return Api.client.get<User>('/user/profile');
  }

  static async getFavorites(): Promise<string[]> {
    if (AppConfig.USE_MOCK) return MockData.getFavorites();
    const favs = await Api.client.get<string[]>('/user/favorites');
    AppStorage.setOrCreate<string[]>('favorites', favs);
    return favs;
  }

  static async getFavoriteDishes(): Promise<Dish[]> {
    if (AppConfig.USE_MOCK) return MockData.getFavoriteDishes();
    return Api.client.get<Dish[]>('/user/favorites/dishes');
  }

  static async toggleFavorite(dishId: string): Promise<string[]> {
    if (AppConfig.USE_MOCK) return MockData.toggleFavorite(dishId);
    const body: Record<string, string> = { 'dishId': dishId };
    const favs = await Api.client.post<string[]>('/user/favorites', body);
    AppStorage.setOrCreate<string[]>('favorites', favs);
    return favs;
  }

  /** 上传评价图片，返回可访问 URL（Mock 模式直接返回原路径） */
  static async uploadReviewImage(path: string): Promise<string> {
    if (AppConfig.USE_MOCK) return path;
    return Api.client.uploadImage(path);
  }
}
