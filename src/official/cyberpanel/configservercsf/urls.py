from django.conf.urls import url
from . import views

urlpatterns = [

    url(r'^$', views.configservercsf, name='configservercsf'),
    url(r'^iframe/$', views.configservercsfiframe, name='configservercsfiframe'),
]
