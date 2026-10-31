# الحوار الصوتي والشفاه والواقعية البصرية

## حوار صوتي
النظام يدعم مفتاح `"audio": "res://assets/audio/voice/....wav"` داخل سطور JSON.
ضع ملفات WAV/OGG مرخّصة في `assets/audio/voice/` واربطها في `data/dialogue/campaign_dialogues.json`.

## مزامنة شفاه
تتطلب:
- نموذج بوجه فيه Blend Shapes / Visemes
- أو أداة خارجية (مثل OVR LipSync)  
البديل الحالي في المشروع: نبض فك بسيط — **ليس** lip-sync حقيقي.

## فوتوغرافي
الأصول الحالية Kenney/KayKit stylized.
للترقية: استبدال تدريجي بنماذج PBR عالية (مراعاة ميزانية الموبايل وLOD).
