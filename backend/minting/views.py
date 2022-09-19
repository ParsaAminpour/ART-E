from django.shortcuts import render
from django.core.exceptions import PermissionDenied
from django.views import View
from django.http import HttpResponse
from django.shortcuts import render


class Home(View):
    def get(self, request):
        return HttpResponse("<center><h1> The front section has NOT completed yet</h1></center>")
    