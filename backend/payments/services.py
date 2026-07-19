import uuid
from typing import Dict, Any

class MockPaymentService:
    """
    Simule une intégration avec un fournisseur de Mobile Money (CinétPay, FedaPay, LigdiCash).
    """

    @classmethod
    def initiate_payment(cls, payment) -> Dict[str, Any]:
        """
        Génère un faux lien de paiement et un ID de transaction.
        'payment' est l'instance du modèle Payment.
        """
        transaction_id = f"TX_{uuid.uuid4().hex[:12].upper()}"
        
        # En environnement réel, on ferait un appel POST à l'API du partenaire
        # et on récupérerait l'URL de redirection de paiement.
        
        payment_url = f"https://mock-payment-gateway.sansgato.com/pay/{transaction_id}"
        
        return {
            "success": True,
            "transaction_id": transaction_id,
            "payment_url": payment_url,
            "message": "Paiement initié avec succès (Mock)."
        }

    @classmethod
    def verify_payment(cls, transaction_id: str) -> Dict[str, Any]:
        """
        Simule la vérification du statut d'une transaction.
        """
        return {
            "success": True,
            "status": "paye",
            "message": "Paiement validé."
        }
