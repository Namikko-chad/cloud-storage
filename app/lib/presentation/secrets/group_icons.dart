import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../common/hm.dart';

/// A built-in group picture: a glyph on a tinted square.
class GroupPreset {
  const GroupPreset(this.icon, this.en, this.ru, this.color);

  final IconData icon;
  final String en;
  final String ru;
  final Color color;

  String get label => tr(en, ru);
}

class GroupPresetCategory {
  const GroupPresetCategory(this.en, this.ru, this.items);

  final String en;
  final String ru;
  final List<GroupPreset> items;

  String get label => tr(en, ru);
}

/// Colours a preset may take: the status tokens (§ 1.2).
const groupIconColors = [HmColors.accent, HmColors.active, HmColors.ok, HmColors.warning, HmColors.error, HmColors.purple, HmColors.muted];

/// Purple glyphs use the lighter shade for contrast (§ 1.2).
Color _glyph(Color c) => c == HmColors.purple ? HmColors.purpleLight : c;

const _a = HmColors.accent, _b = HmColors.active, _g = HmColors.ok, _y = HmColors.warning;
const _r = HmColors.error, _p = HmColors.purple, _m = HmColors.muted;

const groupPresets = <GroupPresetCategory>[
  GroupPresetCategory('General', 'Общее', [
    GroupPreset(Icons.person_outline, 'Personal', 'Личное', _a),
    GroupPreset(Icons.family_restroom, 'Family', 'Семья', _g),
    GroupPreset(Icons.home_outlined, 'Home', 'Дом', _y),
    GroupPreset(Icons.work_outline, 'Work', 'Работа', _b),
    GroupPreset(Icons.star_outline, 'Favourites', 'Избранное', _y),
    GroupPreset(Icons.push_pin_outlined, 'Pinned', 'Закреплённое', _r),
    GroupPreset(Icons.lock_outline, 'Private', 'Приватное', _p),
    GroupPreset(Icons.archive_outlined, 'Archive', 'Архив', _m),
    GroupPreset(Icons.folder_outlined, 'Folder', 'Папка', _a),
    GroupPreset(Icons.label_outline, 'Other', 'Прочее', _m),
  ]),
  GroupPresetCategory('Communication', 'Общение', [
    GroupPreset(Icons.mail_outline, 'Email', 'Почта', _a),
    GroupPreset(Icons.alternate_email, 'Accounts', 'Аккаунты', _b),
    GroupPreset(Icons.chat_bubble_outline, 'Messengers', 'Мессенджеры', _g),
    GroupPreset(Icons.forum_outlined, 'Forums', 'Форумы', _p),
    GroupPreset(Icons.groups_outlined, 'Social', 'Соцсети', _b),
    GroupPreset(Icons.phone_outlined, 'Phone', 'Телефон', _g),
    GroupPreset(Icons.contacts_outlined, 'Contacts', 'Контакты', _y),
    GroupPreset(Icons.public, 'Websites', 'Сайты', _a),
    GroupPreset(Icons.video_call_outlined, 'Video calls', 'Видеозвонки', _r),
    GroupPreset(Icons.rss_feed, 'News', 'Новости', _y),
  ]),
  GroupPresetCategory('Money', 'Деньги', [
    GroupPreset(Icons.account_balance_outlined, 'Banks', 'Банки', _b),
    GroupPreset(Icons.credit_card, 'Cards', 'Карты', _a),
    GroupPreset(Icons.payments_outlined, 'Payments', 'Платежи', _g),
    GroupPreset(Icons.savings_outlined, 'Savings', 'Накопления', _y),
    GroupPreset(Icons.trending_up, 'Investments', 'Инвестиции', _g),
    GroupPreset(Icons.receipt_long_outlined, 'Bills', 'Счета', _m),
    GroupPreset(Icons.account_balance_wallet_outlined, 'Wallets', 'Кошельки', _p),
    GroupPreset(Icons.currency_bitcoin, 'Crypto', 'Крипта', _y),
    GroupPreset(Icons.request_quote_outlined, 'Taxes', 'Налоги', _r),
    GroupPreset(Icons.currency_exchange, 'Exchanges', 'Биржи', _a),
  ]),
  GroupPresetCategory('Development & IT', 'Разработка и IT', [
    GroupPreset(Icons.code, 'Code', 'Код', _a),
    GroupPreset(Icons.terminal, 'SSH', 'SSH', _g),
    GroupPreset(Icons.dns_outlined, 'Servers', 'Серверы', _b),
    GroupPreset(Icons.cloud_outlined, 'Cloud', 'Облако', _a),
    GroupPreset(Icons.storage, 'Databases', 'Базы данных', _y),
    GroupPreset(Icons.api, 'API keys', 'API-ключи', _p),
    GroupPreset(Icons.commit, 'Git', 'Git', _r),
    GroupPreset(Icons.router_outlined, 'Network', 'Сеть', _b),
    GroupPreset(Icons.vpn_lock_outlined, 'VPN', 'VPN', _g),
    GroupPreset(Icons.wifi, 'Wi-Fi', 'Wi-Fi', _a),
    GroupPreset(Icons.bug_report_outlined, 'Testing', 'Тестирование', _r),
    GroupPreset(Icons.memory, 'Hardware', 'Железо', _m),
  ]),
  GroupPresetCategory('Security', 'Безопасность', [
    GroupPreset(Icons.shield_outlined, 'Security', 'Безопасность', _g),
    GroupPreset(Icons.key_outlined, 'Keys', 'Ключи', _y),
    GroupPreset(Icons.password, 'Passwords', 'Пароли', _a),
    GroupPreset(Icons.pin_outlined, 'PIN codes', 'PIN-коды', _b),
    GroupPreset(Icons.verified_user_outlined, '2FA', '2FA', _g),
    GroupPreset(Icons.admin_panel_settings_outlined, 'Admin', 'Админка', _r),
    GroupPreset(Icons.fingerprint, 'Biometrics', 'Биометрия', _p),
    GroupPreset(Icons.lock_reset, 'Recovery codes', 'Коды восстановления', _r),
  ]),
  GroupPresetCategory('Work & study', 'Работа и учёба', [
    GroupPreset(Icons.business_center_outlined, 'Business', 'Бизнес', _b),
    GroupPreset(Icons.rocket_launch_outlined, 'Projects', 'Проекты', _p),
    GroupPreset(Icons.analytics_outlined, 'Analytics', 'Аналитика', _a),
    GroupPreset(Icons.campaign_outlined, 'Marketing', 'Маркетинг', _y),
    GroupPreset(Icons.design_services_outlined, 'Design', 'Дизайн', _r),
    GroupPreset(Icons.support_agent, 'Support', 'Поддержка', _g),
    GroupPreset(Icons.event_outlined, 'Calendar', 'Календарь', _b),
    GroupPreset(Icons.edit_note, 'Notes', 'Заметки', _y),
    GroupPreset(Icons.school_outlined, 'Education', 'Учёба', _a),
    GroupPreset(Icons.science_outlined, 'Science', 'Наука', _g),
  ]),
  GroupPresetCategory('Shopping & food', 'Покупки и еда', [
    GroupPreset(Icons.shopping_cart_outlined, 'Shopping', 'Покупки', _a),
    GroupPreset(Icons.storefront_outlined, 'Stores', 'Магазины', _b),
    GroupPreset(Icons.sell_outlined, 'Marketplaces', 'Маркетплейсы', _p),
    GroupPreset(Icons.local_shipping_outlined, 'Delivery', 'Доставка', _y),
    GroupPreset(Icons.card_giftcard, 'Gifts & bonuses', 'Подарки и бонусы', _r),
    GroupPreset(Icons.shopping_basket_outlined, 'Groceries', 'Продукты', _g),
    GroupPreset(Icons.restaurant_outlined, 'Restaurants', 'Рестораны', _y),
    GroupPreset(Icons.local_cafe_outlined, 'Cafes', 'Кафе', _m),
  ]),
  GroupPresetCategory('Fun & media', 'Досуг и медиа', [
    GroupPreset(Icons.sports_esports_outlined, 'Games', 'Игры', _p),
    GroupPreset(Icons.live_tv_outlined, 'Streaming', 'Стриминг', _r),
    GroupPreset(Icons.movie_outlined, 'Movies', 'Кино', _y),
    GroupPreset(Icons.music_note_outlined, 'Music', 'Музыка', _g),
    GroupPreset(Icons.podcasts, 'Podcasts', 'Подкасты', _p),
    GroupPreset(Icons.menu_book_outlined, 'Books', 'Книги', _b),
    GroupPreset(Icons.photo_camera_outlined, 'Photos', 'Фото', _a),
    GroupPreset(Icons.casino_outlined, 'Betting', 'Ставки', _r),
  ]),
  GroupPresetCategory('Travel & transport', 'Поездки и транспорт', [
    GroupPreset(Icons.flight_outlined, 'Flights', 'Авиабилеты', _a),
    GroupPreset(Icons.hotel_outlined, 'Hotels', 'Отели', _p),
    GroupPreset(Icons.luggage_outlined, 'Travel', 'Путешествия', _y),
    GroupPreset(Icons.train_outlined, 'Trains', 'Поезда', _b),
    GroupPreset(Icons.directions_car_outlined, 'Car', 'Автомобиль', _g),
    GroupPreset(Icons.local_taxi_outlined, 'Taxi', 'Такси', _y),
    GroupPreset(Icons.local_gas_station_outlined, 'Fuel', 'Топливо', _r),
    GroupPreset(Icons.map_outlined, 'Maps', 'Карты', _g),
  ]),
  GroupPresetCategory('Health & life', 'Здоровье и быт', [
    GroupPreset(Icons.favorite_border, 'Health', 'Здоровье', _r),
    GroupPreset(Icons.local_hospital_outlined, 'Medicine', 'Медицина', _r),
    GroupPreset(Icons.fitness_center, 'Sport', 'Спорт', _g),
    GroupPreset(Icons.spa_outlined, 'Wellness', 'Красота', _p),
    GroupPreset(Icons.child_care, 'Kids', 'Дети', _y),
    GroupPreset(Icons.pets, 'Pets', 'Питомцы', _y),
    GroupPreset(Icons.bolt, 'Utilities', 'ЖКХ', _y),
    GroupPreset(Icons.apartment_outlined, 'Real estate', 'Недвижимость', _b),
  ]),
  GroupPresetCategory('Documents', 'Документы', [
    GroupPreset(Icons.badge_outlined, 'ID documents', 'Удостоверения', _a),
    GroupPreset(Icons.assignment_ind_outlined, 'Public services', 'Госуслуги', _b),
    GroupPreset(Icons.health_and_safety_outlined, 'Insurance', 'Страховка', _g),
    GroupPreset(Icons.gavel, 'Legal', 'Юридическое', _m),
    GroupPreset(Icons.description_outlined, 'Documents', 'Документы', _a),
    GroupPreset(Icons.draw_outlined, 'Signatures', 'Подписи', _p),
  ]),
  GroupPresetCategory('Devices', 'Устройства', [
    GroupPreset(Icons.smartphone_outlined, 'Phones', 'Телефоны', _a),
    GroupPreset(Icons.laptop_outlined, 'Computers', 'Компьютеры', _b),
    GroupPreset(Icons.tv_outlined, 'TV', 'ТВ', _p),
    GroupPreset(Icons.watch_outlined, 'Watches', 'Часы', _g),
    GroupPreset(Icons.videocam_outlined, 'Cameras', 'Камеры', _r),
    GroupPreset(Icons.print_outlined, 'Printers', 'Принтеры', _m),
    GroupPreset(Icons.sensors_outlined, 'Smart home', 'Умный дом', _y),
    GroupPreset(Icons.headphones_outlined, 'Audio', 'Аудио', _b),
  ]),
];

/// Draws a preset as a square PNG: the glyph on a tinted square with a ring
/// and a faint grid, like the rest of the UI. Opaque, so it looks the same
/// on any surface. Corners are rounded by [GroupAvatar] when shown.
Future<Uint8List> renderGroupIcon(IconData icon, Color color, {int side = 128}) async {
  final s = side.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, s, s);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s / 4));

  canvas.drawRect(rect, Paint()..color = HmColors.surface);
  canvas.drawRRect(rrect, Paint()..color = HmColors.tint(color, HmColors.badge));

  // Grid overlay (§ 2.2), 4 cells across.
  canvas.save();
  canvas.clipRRect(rrect);
  final grid = Paint()
    ..color = HmColors.tint(color, 0.08)
    ..strokeWidth = s / 128;
  for (var i = 1; i < 4; i++) {
    final p = s * i / 4;
    canvas.drawLine(Offset(p, 0), Offset(p, s), grid);
    canvas.drawLine(Offset(0, p), Offset(s, p), grid);
  }
  canvas.restore();

  final ring = s / 32;
  canvas.drawRRect(
    rrect.deflate(ring / 2),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring
      ..color = HmColors.tint(color, HmColors.ring),
  );

  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: s * 0.56, color: _glyph(color), height: 1),
    ),
  )..layout();
  glyph.paint(canvas, Offset((s - glyph.width) / 2, (s - glyph.height) / 2));
  glyph.dispose();

  final img = await recorder.endRecording().toImage(side, side);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return png!.buffer.asUint8List();
}

/// A preset with the colour it was picked in.
typedef GroupIconChoice = ({GroupPreset preset, Color color});

/// Opens the gallery of built-in pictures.
Future<GroupIconChoice?> pickGroupIcon(BuildContext context) => showHmModal<GroupIconChoice>(
  context,
  title: tr('Choose a picture', 'Выбор картинки'),
  size: HmModalSize.lg,
  body: (_) => const _Gallery(),
  actions: (ctx) => [
    HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx)),
  ],
);

class _Gallery extends StatefulWidget {
  const _Gallery();

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _query = TextEditingController();

  /// null: each preset in its own colour.
  Color? _color;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(GroupPreset p, GroupPresetCategory c) {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [p.en, p.ru, c.en, c.ru].any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final cats = [
      for (final c in groupPresets)
        if (c.items.where((p) => _matches(p, c)).toList() case final items when items.isNotEmpty) (cat: c, items: items),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            HmSearchField(controller: _query, onChanged: (_) => setState(() {})),
            _Swatch(color: null, selected: _color == null, onTap: () => setState(() => _color = null)),
            for (final c in groupIconColors) _Swatch(color: c, selected: _color == c, onTap: () => setState(() => _color = c)),
          ],
        ),
        SizedBox(height: hm.gapSm),
        if (cats.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              tr('Nothing found', 'Ничего не найдено'),
              style: HmText.small.copyWith(color: HmColors.muted),
              textAlign: TextAlign.center,
            ),
          ),
        for (final c in cats) ...[
          HmSectionTitle(c.cat.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in c.items)
                _Tile(preset: p, color: _color ?? p.color, onTap: () => Navigator.pop(context, (preset: p, color: _color ?? p.color))),
            ],
          ),
          SizedBox(height: hm.gapSm),
        ],
      ],
    );
  }
}

/// A live preview of [renderGroupIcon], drawn with widgets.
class GroupIconPreview extends StatelessWidget {
  const GroupIconPreview({super.key, required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: HmColors.tint(color, HmColors.badge),
      borderRadius: BorderRadius.circular(size / 4),
      border: Border.all(color: HmColors.tint(color, HmColors.ring)),
    ),
    child: Icon(icon, size: size * 0.56, color: _glyph(color)),
  );
}

class _Tile extends StatefulWidget {
  const _Tile({required this.preset, required this.color, required this.onTap});

  final GroupPreset preset;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final mobile = Hm.of(context).mobile;
    return Tooltip(
      message: widget.preset.label,
      child: Semantics(
        button: true,
        label: widget.preset.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hot = true),
          onExit: (_) => setState(() => _hot = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HmColors.tint(widget.color, _hot ? HmColors.resting : 0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _hot ? HmColors.tint(widget.color, HmColors.ring) : Colors.transparent),
              ),
              child: GroupIconPreview(icon: widget.preset.icon, color: widget.color, size: mobile ? 44 : 36),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap});

  /// null: "own colours".
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = Hm.of(context).mobile ? 32.0 : 22.0;
    final c = color ?? HmColors.text;
    final swatch = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color == null ? null : HmColors.tint(c, HmColors.ring),
            gradient: color == null
                ? const SweepGradient(
                    colors: [HmColors.accent, HmColors.ok, HmColors.warning, HmColors.error, HmColors.purple, HmColors.accent],
                  )
                : null,
            border: Border.all(color: selected ? HmColors.text : c, width: selected ? 2 : 1),
          ),
          child: selected ? Icon(Icons.check, size: size * 0.6, color: HmColors.text) : null,
        ),
      ),
    );
    return color == null ? Tooltip(message: tr('Own colours', 'Свои цвета'), child: swatch) : swatch;
  }
}
