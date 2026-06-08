"""
جلب البيانات الحقيقية من Firestore لمشروع عين رقيب
"""
import firebase_admin
from firebase_admin import credentials, firestore

# استخدام Application Default Credentials أو Service Account
# نجرب بدون credentials أولاً (إذا firebase-admin مثبت)
try:
    app = firebase_admin.get_app()
except ValueError:
    # تهيئة بدون service account - سيستخدم الـ project ID فقط للقراءة
    firebase_admin.initialize_app(options={
        'projectId': 'ayn-raqeeb'
    })

db = firestore.client()

COLLECTIONS = ['schools', 'parents', 'drivers', 'students', 'users']

for col_name in COLLECTIONS:
    print(f'\n{"="*50}')
    print(f'Collection: {col_name}')
    print('='*50)
    try:
        docs = db.collection(col_name).limit(5).stream()
        count = 0
        for doc in docs:
            count += 1
            data = doc.to_dict()
            print(f'\n  Doc ID: {doc.id}')
            # اطبع الحقول المهمة فقط
            important_fields = ['name', 'school_name', 'email', 'phone', 
                              'password', 'parent_id', 'school_id', 
                              'driver_id', 'username', 'id', 'bus_number',
                              'parent_name', 'driver_name', 'student_name']
            for field in important_fields:
                if field in data:
                    print(f'    {field}: {data[field]}')
        if count == 0:
            print('  (فارغة)')
    except Exception as e:
        print(f'  خطأ: {e}')
