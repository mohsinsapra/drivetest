# Subscription Product Exam Picture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `exam_picture` image field to `BCDSubscriptionProduct` so admins can upload an exam illustration from Django Admin and the API returns its relative path for Flutter to display.

**Architecture:** Add `ImageField` to the model (files land under `MEDIA_ROOT/bcd/subscription_products/` so the existing `BCDMediaView` serves them), expose the relative path via a `SerializerMethodField` in the existing `BCDSubscriptionProductSerializer`, and surface an upload widget + preview in the Django Admin fieldset.

**Tech Stack:** Django 4.x, Django REST Framework, Pillow (already installed), SQLite/MySQL via Django ORM.

**Backend root:** `taxi_exam_backend/` (all paths below are relative to it)

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `questions/models.py` | Modify line 246 area | Add `exam_picture` ImageField to `BCDSubscriptionProduct` |
| `questions/migrations/0020_bcdsubscriptionproduct_exam_picture.py` | Create | Migration for the new field |
| `questions/serializers_v2.py` | Modify lines 71–91 | Add `exam_picture` SerializerMethodField |
| `bcd/admin.py` | Modify lines 491–546 | Add preview helper + Exam Picture fieldset |
| `questions/tests.py` | Modify | Tests for serializer output |

---

## Task 1: Add `exam_picture` field to the model

**Files:**
- Modify: `questions/models.py:237–254`

- [ ] **Step 1: Add the field**

Open `questions/models.py`. Inside `BCDSubscriptionProduct` (starting at line 237), add `exam_picture` after `is_free`:

```python
class BCDSubscriptionProduct(models.Model):
    """BCD subscription / course product (from subscriptions.json)."""
    bcd_id        = models.IntegerField(unique=True)
    name          = EncryptedTextField()                        # ENCRYPTED
    price         = EncryptedTextField()                        # ENCRYPTED
    currency      = models.CharField(max_length=10, default='SEK')  # PLAINTEXT
    iap_product_id = EncryptedTextField(null=True, blank=True)  # ENCRYPTED
    duration_days = models.IntegerField(default=60)             # PLAINTEXT
    sort_order    = models.IntegerField(null=True, blank=True)  # PLAINTEXT
    is_active     = models.BooleanField(default=True)
    is_free       = models.BooleanField(default=False)
    exam_picture  = models.ImageField(
        upload_to='bcd/subscription_products/',
        null=True,
        blank=True,
    )

    class Meta:
        verbose_name        = 'BCD Subscription Product'
        verbose_name_plural = 'BCD Subscription Products'

    def __str__(self):
        return self.name or f'BCD Sub #{self.bcd_id}'
```

- [ ] **Step 2: Create the migration**

```bash
cd taxi_exam_backend
python manage.py makemigrations questions --name add_exam_picture_to_bcd_subscription_product
```

Expected output:
```
Migrations for 'questions':
  questions/migrations/0020_add_exam_picture_to_bcd_subscription_product.py
    - Add field exam_picture to bcdsubscriptionproduct
```

- [ ] **Step 3: Apply the migration**

```bash
python manage.py migrate
```

Expected output ends with:
```
Applying questions.0020_add_exam_picture_to_bcd_subscription_product... OK
```

- [ ] **Step 4: Commit**

```bash
git add questions/models.py questions/migrations/0020_add_exam_picture_to_bcd_subscription_product.py
git commit -m "feat: add exam_picture ImageField to BCDSubscriptionProduct"
```

---

## Task 2: Write and pass serializer tests

**Files:**
- Modify: `questions/tests.py`

- [ ] **Step 1: Write the failing tests**

Replace the contents of `questions/tests.py` with:

```python
from django.test import TestCase
from questions.models import BCDSubscriptionProduct
from questions.serializers_v2 import BCDSubscriptionProductSerializer


class BCDSubscriptionProductSerializerTests(TestCase):

    def _make_product(self, **kwargs):
        defaults = dict(
            bcd_id=999,
            name="Test Product",
            price="100",
            currency="SEK",
            duration_days=60,
            is_active=True,
            is_free=False,
        )
        defaults.update(kwargs)
        return BCDSubscriptionProduct.objects.create(**defaults)

    def test_exam_picture_is_null_when_not_set(self):
        product = self._make_product()
        data = BCDSubscriptionProductSerializer(product).data
        self.assertIn("exam_picture", data)
        self.assertIsNone(data["exam_picture"])

    def test_exam_picture_returns_relative_path_when_set(self):
        product = self._make_product(bcd_id=998)
        # Simulate a saved path without touching the filesystem
        product.exam_picture.name = "bcd/subscription_products/test.jpg"
        data = BCDSubscriptionProductSerializer(product).data
        self.assertEqual(data["exam_picture"], "bcd/subscription_products/test.jpg")

    def test_exam_picture_field_present_in_serializer_fields(self):
        fields = BCDSubscriptionProductSerializer().fields
        self.assertIn("exam_picture", fields)
```

- [ ] **Step 2: Run tests — expect failure**

```bash
cd taxi_exam_backend
python manage.py test questions.tests.BCDSubscriptionProductSerializerTests -v 2
```

Expected: tests for `exam_picture` fail because the field isn't in the serializer yet.

---

## Task 3: Add `exam_picture` to the serializer

**Files:**
- Modify: `questions/serializers_v2.py:71–91`

- [ ] **Step 1: Update the serializer**

In `questions/serializers_v2.py`, replace the `BCDSubscriptionProductSerializer` class (lines 71–91) with:

```python
class BCDSubscriptionProductSerializer(serializers.ModelSerializer):
    category_bcd_ids = serializers.SerializerMethodField()
    exam_picture = serializers.SerializerMethodField()

    class Meta:
        model = BCDSubscriptionProduct
        fields = [
            "id",
            "bcd_id",
            "name",
            "price",
            "currency",
            "iap_product_id",
            "duration_days",
            "sort_order",
            "is_active",
            "is_free",
            "category_bcd_ids",
            "exam_picture",
        ]

    def get_category_bcd_ids(self, obj):
        return list(obj.category_links.filter(is_active=True).values_list('bcd_category_id', flat=True))

    def get_exam_picture(self, obj):
        if obj.exam_picture:
            return obj.exam_picture.name
        return None
```

- [ ] **Step 2: Run tests — expect pass**

```bash
cd taxi_exam_backend
python manage.py test questions.tests.BCDSubscriptionProductSerializerTests -v 2
```

Expected:
```
test_exam_picture_field_present_in_serializer_fields ... ok
test_exam_picture_is_null_when_not_set ... ok
test_exam_picture_returns_relative_path_when_set ... ok

Ran 3 tests in 0.XXXs

OK
```

- [ ] **Step 3: Commit**

```bash
git add questions/serializers_v2.py questions/tests.py
git commit -m "feat: expose exam_picture in BCDSubscriptionProductSerializer"
```

---

## Task 4: Add image upload and preview to Django Admin

**Files:**
- Modify: `bcd/admin.py:491–546`

- [ ] **Step 1: Update `BCDSubscriptionProductAdmin`**

In `bcd/admin.py`, replace the `BCDSubscriptionProductAdmin` class (from `@admin.register(BCDSubscriptionProduct)` at line 491 to the end of the class at line 546) with:

```python
@admin.register(BCDSubscriptionProduct)
class BCDSubscriptionProductAdmin(_CacheBustMixin, admin.ModelAdmin):
    list_display = [
        "bcd_id",
        "preview_name",
        "preview_price",
        "currency",
        "duration_days",
        "sort_order",
        "is_active",
        "is_free",
    ]
    list_filter = ["currency", "is_active", "is_free"]
    search_fields = [
        "bcd_id"
    ]  # non-empty required; real search is in get_search_results
    readonly_fields = ["bcd_id", "exam_picture_preview"]
    inlines = [BCDSubscriptionCategoryInline]

    fieldsets = [
        (
            "Identification",
            {
                "fields": [
                    "bcd_id",
                    "currency",
                    "duration_days",
                    "sort_order",
                    "is_active",
                    "is_free",
                ],
            },
        ),
        (
            "Content  (stored encrypted in DB — displayed decrypted here)",
            {
                "fields": ["name", "price", "iap_product_id"],
            },
        ),
        (
            "Exam Picture",
            {
                "fields": ["exam_picture_preview", "exam_picture"],
            },
        ),
    ]

    @admin.display(description="Current picture")
    def exam_picture_preview(self, obj):
        if obj.exam_picture:
            from django.utils.html import format_html
            return format_html('<img src="{}" style="max-height:120px;" />', obj.exam_picture.url)
        return "—"

    @admin.display(description="Name")
    def preview_name(self, obj):
        return _strip(obj.name) or "—"

    @admin.display(description="Price")
    def preview_price(self, obj):
        price = _strip(obj.price)
        return f"{price} {obj.currency}".strip() if price else "—"

    def get_search_results(self, request, queryset, search_term):
        if not search_term:
            return queryset, False
        term = search_term.lower()
        pks = [o.pk for o in queryset if term in _strip(o.name or "").lower()]
        return queryset.filter(pk__in=pks), False
```

- [ ] **Step 2: Verify admin loads without errors**

```bash
cd taxi_exam_backend
python manage.py check
```

Expected:
```
System check identified no issues (0 silenced).
```

- [ ] **Step 3: Commit**

```bash
git add bcd/admin.py
git commit -m "feat: add exam_picture upload and preview to BCDSubscriptionProductAdmin"
```

---

## Task 5: Manual smoke test

- [ ] **Step 1: Start the dev server**

```bash
cd taxi_exam_backend
python manage.py runserver
```

- [ ] **Step 2: Open Django Admin and upload a picture**

1. Navigate to `http://localhost:8000/admin/`
2. Go to **BCD Subscription Products** → open any product
3. Scroll to the **Exam Picture** section
4. Upload a `.jpg` or `.png` file and click **Save**
5. Confirm the image preview appears after save

- [ ] **Step 3: Verify the API returns the path**

```bash
curl -s http://localhost:8000/api/v2/subscription-products/ | python -m json.tool | grep exam_picture
```

Expected (for the product you uploaded to):
```json
"exam_picture": "bcd/subscription_products/your-image.jpg"
```

Expected (for products with no image):
```json
"exam_picture": null
```

- [ ] **Step 4: Verify the image is served via bcd-media**

Take the path from the previous step and request it:

```bash
curl -I "http://localhost:8000/api/bcd-media/bcd/subscription_products/your-image.jpg/"
```

Expected: `HTTP/1.1 200 OK` with `Content-Type: image/jpeg` (or `image/png`).
