from rest_framework import serializers
from .models import Payment

class PaymentSerializer(serializers.ModelSerializer):
    payment_method_label = serializers.CharField(source="get_payment_method_display", read_only=True)
    payment_status_label = serializers.CharField(source="get_payment_status_display", read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id", "montant", "payment_method", "payment_method_label", 
            "payment_status", "payment_status_label", "transaction_id", 
            "created_at", "updated_at"
        ]
