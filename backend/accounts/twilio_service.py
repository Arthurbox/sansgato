import logging
from django.conf import settings
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException

logger = logging.getLogger(__name__)

def send_verification_otp(phone_number):
    """
    Démarre la vérification OTP par SMS via Twilio Verify.
    Si Twilio n'est pas configuré et qu'on est en DEBUG, on génère et stocke un code en local.
    """
    # Bypass pour l'admin supreme pour eviter le blocage par Twilio
    is_admin_test = phone_number in ['+22657428929', '57428929']
    
    if is_admin_test or not all([settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN, settings.TWILIO_VERIFY_SERVICE_SID]):
        if settings.DEBUG or is_admin_test:
            import random
            from django.utils import timezone
            from datetime import timedelta
            from .models import OTPVerification

            # Génération d'un code OTP fixe pour l'admin test, aléatoire sinon
            code = "123456" if is_admin_test else f"{random.randint(100000, 999999)}"
            expires_at = timezone.now() + timedelta(minutes=10)
            
            # Suppression des anciens OTP non vérifiés pour ce numéro
            OTPVerification.objects.filter(phone_number=phone_number, is_verified=False).delete()
            
            # Enregistrement du nouveau code
            OTPVerification.objects.create(
                phone_number=phone_number,
                code=code,
                expires_at=expires_at,
                purpose='login'  # Valeur par défaut pour contourner le champ requis
            )
            
            # Message visible dans les logs
            logger.warning(
                "\n"
                "========================================================================\n"
                f"[SANDBOX MODE] (TWILIO BYPASSED)\n"
                f"Code OTP genere pour {phone_number} : {code}\n"
                f"Expire a : {expires_at}\n"
                "========================================================================\n"
            )
            print(
                "\n"
                "========================================================================\n"
                f"[SANDBOX MODE] (TWILIO BYPASSED)\n"
                f"Code OTP genere pour {phone_number} : {code}\n"
                "========================================================================\n"
            )
            return None
        else:
            logger.error("Les identifiants Twilio ne sont pas configurés dans settings.")
            raise ValueError("Les identifiants de vérification Twilio ne sont pas configurés sur le serveur.")

    try:
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        verification = client.verify.v2.services(settings.TWILIO_VERIFY_SERVICE_SID) \
                                       .verifications \
                                       .create(to=phone_number, channel='sms')
        return verification
    except TwilioRestException as e:
        logger.error(f"Erreur Twilio Verify lors de l'envoi : {e.msg} (Code: {e.code})")
        raise e

def check_verification_otp(phone_number, code):
    """
    Vérifie si le code OTP fourni pour le numéro de téléphone est correct.
    Retourne True si approuvé, False sinon.
    """
    # Bypass pour l'admin supreme pour eviter le blocage par Twilio
    is_admin_test = phone_number in ['+22657428929', '57428929']

    if is_admin_test or not all([settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN, settings.TWILIO_VERIFY_SERVICE_SID]):
        if settings.DEBUG or is_admin_test:
            from django.utils import timezone
            from .models import OTPVerification
            
            # Recherche d'un OTP valide et non expiré
            otp_record = OTPVerification.objects.filter(
                phone_number=phone_number,
                code=code,
                is_verified=False,
                expires_at__gt=timezone.now()
            ).first()
            
            if otp_record:
                otp_record.is_verified = True
                otp_record.save()
                logger.info(f"Sandbox OTP verifie avec succes pour {phone_number}")
                return True
            logger.warning(f"Tentative de validation OTP Sandbox echouee pour {phone_number} avec le code {code}")
            return False
        else:
            logger.error("Les identifiants Twilio ne sont pas configurés dans settings.")
            raise ValueError("Les identifiants de vérification Twilio ne sont pas configurés sur le serveur.")

    try:
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        verification_check = client.verify.v2.services(settings.TWILIO_VERIFY_SERVICE_SID) \
                                           .verification_checks \
                                           .create(to=phone_number, code=code)
        return verification_check.status == 'approved'
    except TwilioRestException as e:
        logger.warning(f"Erreur Twilio Verify lors de la vérification : {e.msg} (Code: {e.code})")
        # Si le code/ressource a expiré ou n'existe pas, Twilio renvoie une 404. On traite cela comme invalide/expiré (False).
        if e.status == 404 or e.code == 20404:
            return False
        raise e
