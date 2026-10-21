/**
 * 用户数据模型（游客 / 注册用户共用）
 * authType：guest=游客，password=自定义账号，huawei=华为账号
 */
export class User {
  id: string;
  nickname: string;
  avatar: string;
  favorites: string[];
  username: string;
  schoolId: string;
  schoolName: string;
  authType: string;

  constructor(
    id: string = '',
    nickname: string = '',
    avatar: string = '',
    favorites: string[] = [],
    username: string = '',
    schoolId: string = '',
    schoolName: string = '',
    authType: string = 'guest'
  ) {
    this.id = id;
    this.nickname = nickname;
    this.avatar = avatar;
    this.favorites = favorites;
    this.username = username;
    this.schoolId = schoolId;
    this.schoolName = schoolName;
    this.authType = authType;
  }
}
