# Generated by Django 4.0.6 on 2022-09-18 14:05

import datetime
from django.db import migrations, models
from django.utils.timezone import utc


class Migration(migrations.Migration):

    dependencies = [
        ('minting', '0004_alter_art_time_creation'),
    ]

    operations = [
        migrations.AlterField(
            model_name='art',
            name='time_creation',
            field=models.DateTimeField(verbose_name=datetime.datetime(2022, 9, 18, 14, 5, 1, 213418, tzinfo=utc)),
        ),
    ]