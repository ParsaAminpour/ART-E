from importlib.metadata import requires
from ssl import ALERT_DESCRIPTION_INSUFFICIENT_SECURITY
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
         

class ArtMutation(graphene.Mutation):
    class Arguments:
        art_name = graphene.String(required=True)
        art_describe = graphene.String(required=True)
        art_tokenId = graphene.Int()
        art_cid = graphene.String(required=True)
        art_tokenURI = graphene.String(required=True)
    
    art_field = graphene.Field(ArtType)

    @classmethod
    def mutate(cls, art_name_, art_describe_, art_tokenId_, art_cid_, art_tokenURI_):
        that_art = Art.create(
            art_name=art_name_, art_description=art_describe_, art_tokenId=art_tokenId_,
                art_cid=art_cid_, art_tokenURI=art_tokenURI_)
        that_art.save()
        return cls(art_field=that_art)


class bridge_mutation(graphene.ObjectType):
    adding_art = ArtMutation.Field()

schema = graphene.Schema(query=Query, mutation=ArtMutation)

