/**
 * 营养信息
 */
export class Nutrition {
  calories: number;
  isVegetarian: boolean;
  allergens: string[];

  constructor(
    calories: number = 0,
    isVegetarian: boolean = false,
    allergens: string[] = []
  ) {
    this.calories = calories;
    this.isVegetarian = isVegetarian;
    this.allergens = allergens;
  }
}

/**
 * 菜品数据模型（class 形式，供 ArkTS @Prop/@State 使用）
 */
export class Dish {
  id: string;
  stallId: string;
  canteenId: string;
  name: string;
  price: number;
  image: string;
  tags: string[];
  stallName: string;
  canteenName: string;
  floor: number;
  rating: number;
  reviewCount: number;
  isSignature: boolean;
  soldOut: boolean;
  nutrition: Nutrition;

  constructor() {
    this.id = '';
    this.stallId = '';
    this.canteenId = '';
    this.name = '';
    this.price = 0;
    this.image = '';
    this.tags = [];
    this.stallName = '';
    this.canteenName = '';
    this.floor = 0;
    this.rating = 0;
    this.reviewCount = 0;
    this.isSignature = false;
    this.soldOut = false;
    this.nutrition = new Nutrition();
  }
}

/**
 * 餐次类型
 */
export enum MealType {
  BREAKFAST = 'breakfast',
  LUNCH = 'lunch',
  DINNER = 'dinner'
}
