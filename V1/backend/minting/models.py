from pyexpat import model
from tkinter.tix import Balloon
from xmlrpc.client import FastParser
from django.db import models
from cryptoaddress import get_crypto_address
from django.core.validators import RegexValidator
from django.contrib.auth.models import AbstractUser
from django.utils.translation import gettext_lazy as _  
from django.core.exceptions import ValidationError
from django.contrib.auth import hashers
from django.utils import timezone
import json, re, os, hashlib
from web3 import Web3
from rich.console import Console
from dotenv import load_dotenv, find_dotenv
console = Console()

load_dotenv(find_dotenv())

    
class Artist(AbstractUser):
    username = models.CharField(max_length=20, unique=True)
    mail = models.EmailField(max_length=100, null=True, blank=True, unique=False,
        validators=[RegexValidator(r'\w*?\.\w*?\w{5,10}\.com')])

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
        
        self.mail = hashers.make_password(self.mail)
        self.ip_address = hashers.make_password(self.ip_address0)
        super().save(**kwargs)

    def __str__(self):
        return self.username    


class Art(models.Model):
    art_name = models.CharField(max_length=27, null=True, blank=False, unique=True)
    art_description = models.TextField(max_length=256, null=True, blank=False)
    art_tokenId = models.IntegerField(null=True, blank=False, unique=True)
    art_cid = models.CharField(max_length=43, null=True, blank=False, unique=True,
        validators=[RegexValidator(r'^Qm\w{44}')])
    art_tokenURI = models.URLField(max_length=256, null=True, blank=False, unique=True)
    time_creation = models.DateTimeField(timezone.now())
    art_owner = models.ForeignKey(Artist, on_delete=models.CASCADE, null=True, blank=True, default=None)

    def __str__(self):
        return self.art_name
    


class SimpleUser(models.Model):
    username = models.CharField(max_length=20, null=False, blank=False)
    password = models.CharField(max_length=30, null=False, blank=False)

    def save(self, *args, **kwargs):
        re_result = re.match(
            r"(?=^.{8,}$)(?=.*\d)(?=.*[!@#$%^&*]+)(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$",
            self.password)
        if re_result.group() is not self.password:
            raise ValidationError("The password security strenght is not enough")
        
        self.password = hashers.make_password(self.password)
        super().save(**kwargs)
