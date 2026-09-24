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
    return Api.client.get<MyReviewItem[]>('/user/reviews');
  }

  static async getLocalUser(): Promise<User> {
    if (AppConfig.USE_MOCK) return MockData.getLocalUser();
    return Api.client.get<User>('/user/profile');
  }

  static async getFavorites(): Promise<string[]> {
    if (AppConfig.USE_MOCK) return MockData.getFavorites();
    return Api.client.get<string[]>('/user/favorites');
  }

  static async getFavoriteDishes(): Promise<Dish[]> {
    if (AppConfig.USE_MOCK) return MockData.getFavoriteDishes();
    return Api.client.get<Dish[]>('/user/favorites/dishes');
  }

  static async toggleFavorite(dishId: string): Promise<string[]> {
    if (AppConfig.USE_MOCK) return MockData.toggleFavorite(dishId);
    const body: Record<string, string> = { 'dishId': dishId };
    return Api.client.post<string[]>('/user/favorites', body);
  }
}
