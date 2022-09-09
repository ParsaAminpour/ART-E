from django.urls import path
from django.contrib.auth.views import LogoutView
from .views import Home

urlpatterns = [
    path("home/", Home.as_view(), name="home")
]
