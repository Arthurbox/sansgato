from django.db import models

class Payment(models.Model):
    PAYMENT_METHOD_CHOICES = [
        ('mobile_money', 'Mobile Money'),
        ('especes', 'Espèces (à la livraison)'),
    ]

    PAYMENT_STATUS_CHOICES = [
        ('en_attente', 'En attente'),
        ('paye', 'Payé'),
        ('echoue', 'Échoué'),
        ('rembourse', 'Remboursé'),
    ]

    commande = models.ForeignKey('shop.Order', on_delete=models.CASCADE, related_name='payments', verbose_name="Commande")
    montant = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Montant (FCFA)")
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES, default='mobile_money', verbose_name="Méthode de paiement")
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='en_attente', verbose_name="Statut du paiement")
    transaction_id = models.CharField(max_length=100, blank=True, null=True, verbose_name="ID de transaction", help_text="ID renvoyé par l'API de paiement")
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Date création")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Date mise à jour")

    class Meta:
        verbose_name = "Paiement"
        verbose_name_plural = "Paiements"
        ordering = ['-created_at']

    def __str__(self):
        return f"Paiement #{self.id} – Commande #{self.commande.id} ({self.get_payment_status_display()})"
