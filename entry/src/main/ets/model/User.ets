/**
 * 用户数据模型（class 形式，游客模式）
 */
export class User {
  id: string;
  nickname: string;
  avatar: string;
  favorites: string[];

  constructor(
    id: string = '',
    nickname: string = '',
    avatar: string = '',
    favorites: string[] = []
  ) {
    this.id = id;
    this.nickname = nickname;
    this.avatar = avatar;
    this.favorites = favorites;
  }
}
