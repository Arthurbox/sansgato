from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .models import Payment

class PaymentWebhookView(APIView):
    """POST – Webhook pour recevoir les notifications de paiement (Mock)."""
    permission_classes = [AllowAny]

    def post(self, request):
        transaction_id = request.data.get("transaction_id")
        status_paiement = request.data.get("status")

        if not transaction_id or not status_paiement:
            return Response({"detail": "Données invalides."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            payment = Payment.objects.get(transaction_id=transaction_id)
            if status_paiement == "success":
                payment.payment_status = "paye"
                # Mettre à jour le statut global de la commande
                payment.commande.statut = "accepte"
                payment.commande.save()
            elif status_paiement == "failed":
                payment.payment_status = "echoue"
            payment.save()
            return Response({"detail": "Statut mis à jour avec succès."}, status=status.HTTP_200_OK)
        except Payment.DoesNotExist:
            return Response({"detail": "Paiement introuvable."}, status=status.HTTP_404_NOT_FOUND)
