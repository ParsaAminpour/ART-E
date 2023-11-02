from django.urls import path
from django.contrib.auth.views import LogoutView
from .views import Home
from graphene_django.views import GraphQLView
from .schema import schema

urlpatterns = [
    path("home/", Home.as_view(), name="home"),
    path("graphql/", GraphQLView.as_view(graphiql=True, schema=schema))
]
