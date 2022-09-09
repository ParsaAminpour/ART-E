from graphene_django import DjangoObjectType, DjangoListField
import graphene
from .models import Artist, Art

class ArtistType(DjangoObjectType):
    class Meta:
        model = Artist
        fields = '__all__'

class ArtType(DjangoObjectType):
    class Meta:
        model = Art
        fields = '__all__'

class Query(graphene.ObjectType):
    all_arts_of_owner = graphene.Field(
        ArtType, owner_name = graphene.String())

    def resolve_all_arts(root, info, owner_username:str):
        artist = Artist.objects.get(username=owner_username)
        return Art.objects.filter(art_owner = artist)
         

schema = graphene.Schema(query=Query)
  