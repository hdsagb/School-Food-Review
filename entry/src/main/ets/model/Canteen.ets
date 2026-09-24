/**
 * 食堂数据模型（class 形式，供 ArkTS @Prop/@State 使用）
 */
export class Canteen {
  id: string;
  name: string;
  location: string;
  openHours: string;
  floors: number;
  image: string;

  constructor(
    id: string = '',
    name: string = '',
    location: string = '',
    openHours: string = '',
    floors: number = 0,
    image: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.location = location;
    this.openHours = openHours;
    this.floors = floors;
    this.image = image;
  }
}

/**
 * 档口数据模型
 */
export class Stall {
  id: string;
  canteenId: string;
  name: string;
  floor: number;
  cuisine: string;
  image: string;

  constructor(
    id: string = '',
    canteenId: string = '',
    name: string = '',
    floor: number = 0,
    cuisine: string = '',
    image: string = ''
  ) {
    this.id = id;
    this.canteenId = canteenId;
    this.name = name;
    this.floor = floor;
    this.cuisine = cuisine;
    this.image = image;
  }
}
