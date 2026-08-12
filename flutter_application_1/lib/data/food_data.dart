import '../models/food.dart';

const foods = <Food>[
  Food(
    id: 'f1',
    name: 'ข้าวผัดกะเพราหมูกรอบ',
    price: '฿69',
    rating: 4.8,
    category: 'Thai',
    imageAsset: 'assets/restaurant.jpg',
    description: 'ข้าวหอมร้อน ๆ ผัดกะเพรากับหมูกรอบ เสิร์ฟพร้อมไข่ดาว',
  ),
  Food(
    id: 'f2',
    name: 'ข้าวผัดคะน้าทะเล',
    price: '฿79',
    rating: 4.9,
    category: 'Thai',
    imageAsset: 'assets/restaurant.jpg',
    description: 'ข้าวผัดคะน้าพร้อมกุ้งและปลาหมึก รสกลมกล่อม',
  ),
  Food(
    id: 'f3',
    name: 'สเต๊ก',
    price: '฿119',
    rating: 4.7,
    category: 'Main',
    imageAsset: 'assets/restaurant.jpg',
    description: 'สเต๊กเนื้อนุ่ม เสิร์ฟพร้อมผักและเครื่องเคียง',
  ),
  Food(
    id: 'f4',
    name: 'ผัดไทยกุ้ง',
    price: '฿89',
    rating: 4.6,
    category: 'Thai',
    imageAsset: 'assets/restaurant.jpg',
    description: 'ผัดไทยเส้นเหนียวนุ่มพร้อมกุ้งและเครื่องเคียง',
  ),
  Food(
    id: 'f5',
    name: 'ชาไทย',
    price: '฿45',
    rating: 4.8,
    category: 'Drinks',
    imageAsset: 'assets/restaurant.jpg',
    description: 'ชาไทยหอมหวาน เสิร์ฟเย็น',
  ),
];
