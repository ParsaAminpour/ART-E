from django.shortcuts import render
from django.core.exceptions import PermissionDenied
from django.views import View

class Home(View):
    def get(self, request):
        pass
    
    def post(self, request, *args, **kwargs):
        pass
