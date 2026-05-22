# Subscription Product Exam Picture — Design Spec

**Date:** 2026-05-22  
**Status:** Approved (updated: two pictures — day mode + night mode)

## Summary

Add `exam_picture_day` and `exam_picture_night` image fields to `BCDSubscriptionProduct` so admins can upload separate exam illustrations for light and dark themes from Django Admin, and the API returns their relative paths for Flutter to display.

---

## 1. Model Change

**File:** `taxi_exam_backend/questions/models.py`  
**Class:** `BCDSubscriptionProduct`

Add two new fields after `is_free`:

```python
exam_picture_day = models.ImageField(
    upload_to='bcd/subscription_products/',
    null=True,
    blank=True,
)
exam_picture_night = models.ImageField(
    upload_to='bcd/subscription_products/',
    null=True,
    blank=True,
)
```

- Both are optional (`null=True, blank=True`); existing products are unaffected.
- `upload_to='bcd/subscription_products/'` — files land inside `MEDIA_ROOT/bcd/subscription_products/`, served by the existing `BCDMediaView` (`api/bcd-media/<path>/`). No new endpoint needed.
- Requires `Pillow` (already installed).

---

## 2. Migration

```
python manage.py makemigrations questions --name add_exam_picture_day_night_to_bcd_subscription_product
python manage.py migrate
```

Migration file: `0020_add_exam_picture_day_night_to_bcd_subscription_product.py`

---

## 3. Serializer Change

**File:** `taxi_exam_backend/questions/serializers_v2.py`  
**Class:** `BCDSubscriptionProductSerializer`

Add two `SerializerMethodField`s returning the **relative path** or `null`:

```python
exam_picture_day   = serializers.SerializerMethodField()
exam_picture_night = serializers.SerializerMethodField()

def get_exam_picture_day(self, obj):
    if obj.exam_picture_day:
        return obj.exam_picture_day.name
    return None

def get_exam_picture_night(self, obj):
    if obj.exam_picture_night:
        return obj.exam_picture_night.name
    return None
```

Add both to the `fields` list.

**Why relative path?** Matches the existing BCD images pattern — Flutter constructs the full URL via `ApiService.bcdMediaUrl(path)` → `{base}/api/bcd-media/{path}/`.

---

## 4. Admin Change

**File:** `taxi_exam_backend/bcd/admin.py`  
**Class:** `BCDSubscriptionProductAdmin`

Add an **"Exam Pictures"** fieldset with upload widgets and inline previews for both day and night variants:

```python
@admin.display(description="Day picture (current)")
def exam_picture_day_preview(self, obj):
    if obj.exam_picture_day:
        from django.utils.html import format_html
        return format_html('<img src="{}" style="max-height:120px;" />', obj.exam_picture_day.url)
    return "—"

@admin.display(description="Night picture (current)")
def exam_picture_night_preview(self, obj):
    if obj.exam_picture_night:
        from django.utils.html import format_html
        return format_html('<img src="{}" style="max-height:120px;" />', obj.exam_picture_night.url)
    return "—"
```

Fieldset:
```python
(
    "Exam Pictures",
    {
        "fields": [
            "exam_picture_day_preview",
            "exam_picture_day",
            "exam_picture_night_preview",
            "exam_picture_night",
        ],
    },
),
```

Add both preview methods to `readonly_fields`.

---

## 5. API Contract

Endpoint: `GET api/v2/subscription-products/`

New fields in each product object:

```json
{
  "id": 1,
  "bcd_id": 10,
  "name": "BCD Course A",
  ...
  "exam_picture_day":   "bcd/subscription_products/course-a-day.jpg",
  "exam_picture_night": "bcd/subscription_products/course-a-night.jpg"
}
```

- Both values are `null` when no image is uploaded.
- Flutter builds full URL: `bcdMediaUrl("bcd/subscription_products/course-a-day.jpg")` → `{base}/api/bcd-media/bcd/subscription_products/course-a-day.jpg/`
- Flutter picks `exam_picture_day` or `exam_picture_night` based on current theme.

---

## 6. Files to Change

| File | Change |
|------|--------|
| `questions/models.py` | Add `exam_picture_day` + `exam_picture_night` ImageFields |
| `questions/migrations/0020_add_exam_picture_day_night_to_bcd_subscription_product.py` | Auto-generated migration |
| `questions/serializers_v2.py` | Add two SerializerMethodFields + field list entries |
| `bcd/admin.py` | Add two preview helpers + Exam Pictures fieldset |

---

## 7. Out of Scope

- Flutter-side UI changes.
- Image resizing or thumbnail generation.
- Changing the `bcd-media` endpoint (no changes needed).
