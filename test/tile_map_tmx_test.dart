import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mathquest/game/math_world_game.dart';
import 'package:flutter_mathquest/game/npc_question.dart';
import 'package:flutter_mathquest/game/tile_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TileMap TMX parsing', () {
    test('parses TMX width, height, and tile layer data', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" width="2" height="2" tilewidth="16" tileheight="16">
  <layer id="1" name="Tile Layer 1" width="2" height="2">
    <data encoding="csv">1,0,0,2</data>
  </layer>
</map>
''';

      final map = TileMap.parseTmxMap(xml);

      expect(map, isNotNull);
      expect(map!['width'], 2);
      expect(map['height'], 2);
      expect(map['tileWidth'], 16);
      expect(map['tileHeight'], 16);
      expect(map['layers'], isNotEmpty);
      expect((map['layers'] as List).first['data'], [1, 0, 0, 2]);
    });

    test('loads the configured map2.tmx asset and collision data', () async {
      final map = await TileMap.loadMapData();

      expect(map['layers'], isNotEmpty);
      expect(map['worldWidth'], greaterThan(0));
      expect(map['worldHeight'], greaterThan(0));
      expect(map['collisionRectangles'], isNotEmpty);
      expect(map['collisionPolygons'], isNotEmpty);

      final game = MathWorldGame(correctAnswer: 0, problem: '2 + 2')
        ..mapWidth = (map['worldWidth'] as int).toDouble()
        ..mapHeight = (map['worldHeight'] as int).toDouble()
        ..collisionRectangles.addAll(
          (map['collisionRectangles'] as List).cast<Rect>(),
        )
        ..collisionPolygons.addAll(
          (map['collisionPolygons'] as List).cast<List<Offset>>(),
        );
      final questionNpcs = NpcQuestion.createNpcPlacements(
        playerSpawn: Vector2(game.mapWidth / 2, game.mapHeight / 2),
        canOccupy: (center, radius) => game.canPlayerMoveTo(center, radius),
      );
      expect(questionNpcs, hasLength(6));
      expect(
        questionNpcs.map((npc) => npc.questionNumber),
        [1, 2, 3, 4, 5, 6],
      );
      expect(
        questionNpcs.map((npc) => (npc.position.x, npc.position.y)).toList(),
        [
          (535.0, 285.0),
          (1062.0, 340.0),
          (397.0, 553.0),
          (651.0, 584.0),
          (1120.0, 550.0),
          (265.0, 720.0),
        ],
      );
      expect(
        questionNpcs.map((npc) => npc.spriteAssetPath.split('/').last),
        [
          'npc1.png',
          'npc2.jfif',
          'npc3.jfif',
          'npc4.jfif',
          'npc5.jfif',
          'npc6.jfif',
        ],
      );
      for (var index = 0; index < questionNpcs.length; index++) {
        final npc = questionNpcs[index];
        final collisionCenter = npc.position -
            Vector2(0, npc.collisionRadius);
        expect(
          game.canPlayerMoveTo(collisionCenter, npc.collisionRadius),
          isTrue,
        );
        for (final other in questionNpcs.skip(index + 1)) {
          final otherCenter = other.position -
              Vector2(0, other.collisionRadius);
          expect(
            collisionCenter.distanceTo(otherCenter),
            greaterThanOrEqualTo(
              npc.collisionRadius + other.collisionRadius,
            ),
          );
        }
      }
    });
  });
}
