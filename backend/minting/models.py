from xml.dom import ValidationErr
from django.db import models
from cryptoaddress import get_crypto_address
from django.core.validators import RegexValidator
from django.contrib.auth.models import AbstractUser
from django.utils.translation import gettext_lazy as _  
from django.core.exceptions import ValidationError
import json, re, os
from web3 import Web3
from rich.console import Console
from dotenv import load_dotenv, find_dotenv
console = Console()

load_dotenv(find_dotenv())

class Art(models.Model):
    art_name = models.CharField(max_length=27, null=True, blank=True, unique=True)
    art_description = models.TextField(max_length=256, null=True, blank=True)
    art_tokenId = models.IntegerField(null=False, blank=False, unique=True)
    art_cid = models.CharField(max_length=43, null=False, blank=False, unique=True,
        validators=[RegexValidator(r'^Qm\w{44}')])
    art_tokenURI = models.URLField(max_length=256, null=True, blank=True, unique=True)

    def __str__(self):
        return self.art_name
    
    
class Artist(AbstractUser):
    username = models.CharField(max_length=20, unique=True)
    wallet = models.CharField(max_length=52, null=False, blank=False, unique=True)
    ip_address = models.GenericIPAddressField(
        validators=[RegexValidator(r"(192)\.(168)\.\d{2,3}\.\d{2,3}")]
    )
    blocked_user = models.BooleanField(default=False)
    about = models.TextField(max_length=256, null=True, blank=True)

    def save(self, **kwargs):
        w3 = Web3(Web3.HTTPProvider(os.environ.get("INFURA_URI")))
        if not w3.is_address(self.wallet):
            raise ValidationError("wallet address is not valid on rinkeby network")
        
        super().save(**kwargs)

    def __str__(self):
        return self.usernameINFURA_URI  