/**
 * 学校数据模型（class 形式，供 ArkTS 严格模式与 @State 使用）
 * pinyinFull / pinyinInitials 由服务端下发，用于「中文子串 / 全拼 / 首字母」三种检索
 */
export class School {
  id: string;
  name: string;
  level: string;
  city: string;
  pinyinFull: string;
  pinyinInitials: string;

  constructor(
    id: string = '',
    name: string = '',
    level: string = '本科',
    city: string = '上海',
    pinyinFull: string = '',
    pinyinInitials: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.level = level;
    this.city = city;
    this.pinyinFull = pinyinFull;
    this.pinyinInitials = pinyinInitials;
  }
}