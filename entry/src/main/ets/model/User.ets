/**
 * 用户数据模型（游客 / 注册用户共用，username 为空即游客）
 */
export class User {
  id: string;
  nickname: string;
  avatar: string;
  favorites: string[];
  username: string;

  constructor(
    id: string = '',
    nickname: string = '',
    avatar: string = '',
    favorites: string[] = [],
    username: string = ''
  ) {
    this.id = id;
    this.nickname = nickname;
    this.avatar = avatar;
    this.favorites = favorites;
    this.username = username;
  }
}
