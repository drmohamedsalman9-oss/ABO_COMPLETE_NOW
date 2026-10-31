# دليل خبز NavMesh في Godot 4.3

الهدف: الملاحة تلف حول المباني بدقة.

## الخطوات
1. افتح `scenes/world/MainWorld.tscn`
2. أضف أو حدّد `NavigationRegion3D`
3. في المفتش: **Navigation Mesh → New NavigationMesh**
4. اضبط:
   - Agent Radius ≈ 0.4
   - Agent Height ≈ 1.7
   - Max Slope ≈ 45
5. تأكد أن أرضية المدينة والمباني لها Collision
6. من قائمة NavigationRegion3D: **Bake NavigationMesh**
7. احفظ المشهد

## تقسيم المدينة (مستحسن)
- Region للمركز
- Region للشرق / الغرب / الشمال / الجنوب
- لا تعتمد على سطح واحد ضخم بلا عوائق

## تحقق
- شغّل اللعبة
- راقب المشاة والشرطة: هل يلفّوا حول المباني؟
- إن اخترقوا الجدران: أعد الـ Bake بعد التأكد من CollisionLayer
