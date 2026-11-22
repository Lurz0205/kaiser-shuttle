extends Resource
class_name GameTuning

# ==========================================================
# GAME TUNING: 2D GAMEPLAY VỚI ĐỒ HỌA SÂN 2.5D
# ==========================================================

@export_group("Player Movement")
## Tốc độ di chuyển tiến/lùi của người chơi (px/s) - Giảm còn 90% (220.5 px/s) để trận đấu nhịp nhàng
@export var move_speed_x: float = 220.5

@export_group("Court Dimensions (2D Gameplay)")
## Mặt sàn cố định (Y pixel)
@export var floor_y: float = 550.0
## Vị trí cột lưới (X pixel)
@export var net_x: float = 640.0
## Chiều cao lưới (pixel) - Nâng cao lên 110px ngang tầm cổ vận động viên
@export var net_height: float = 110.0
## Vạch biên ngoài cùng bên trái (Baseline Left)
@export var baseline_left: float = 140.0
## Vạch biên ngoài cùng bên phải (Baseline Right)
@export var baseline_right: float = 1140.0
## Vạch giao cầu ngắn bên trái (Short Service Line)
@export var short_service_left: float = 450.0
## Vạch giao cầu ngắn bên phải (Short Service Line)
@export var short_service_right: float = 830.0

@export_group("Shot Profiles")
## Vận tốc cú Smash thường (px/s) - Giảm 5% theo yêu cầu (1390 px/s)
@export var smash_speed: float = 1390.0
## Vận tốc cú Boom Smash (px/s) - Giảm 5% theo yêu cầu (1829 px/s)
@export var boom_smash_speed: float = 1829.0
## Vận tốc cú Drive ngang mặt lưới (px/s) - Tăng thêm 10% (1056 px/s)
@export var drive_speed: float = 1056.0
## Độ cao đỉnh cú Phông cầu (Clear) so với mặt đất (px) - Cao vút lên khán đài
@export var clear_apex_h: float = 400.0
## Thời gian bay cú Clear (s) - Tốc độ cầu giảm 5% (Thời gian bay điều chỉnh lên 2.08s)
@export var clear_flight_time: float = 2.08
## Độ cao đỉnh cú Bỏ nhỏ (Drop) so với mặt đất (px)
@export var drop_apex_h: float = 126.0
## Thời gian bay cú Drop (s) - Tốc độ cầu tăng 10% (Thời gian bay rút còn 1.05s)
@export var drop_flight_time: float = 1.05
## Độ cao đỉnh cú Bung cầu / Cứu cầu thấp tay (Lift) so với mặt đất (px)
@export var lift_apex_h: float = 360.0
## Thời gian bay cú Lift (s) - Tốc độ cầu tăng 10% (Thời gian bay rút còn 1.85s)
@export var lift_flight_time: float = 1.85
