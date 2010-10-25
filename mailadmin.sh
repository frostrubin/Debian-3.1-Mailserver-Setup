#!/bin/sh

FILE="choice.$$"
NICK=""
NAME=""

rm -f $FILE

show_menu()
{ 
  whiptail --menu "Was wollen Sie tun?" 12 69 3 Erstellen	\
  "Neuen Account einrichten" Weiterleitung 			\
  "Weiterleitung auf andere eMail-Adresse  einrichten" L�schen	\
  "Account l�schen" 2> $FILE || exit
} 

show_list()
{
  # Eine Liste der Lehrer mit Mailaccounts
  # erstellen und so formatieren, dass diese von
  # whiptail gelesen werden kann
  LIST=$(grep "/bin/schule" /etc/passwd                           \
       | cut -d: -f1,5                                         \
       | sed -e s/:/@schule.de\ \"/g -e s/$/\"/g \
       | tr "\n" " ")

  if [ "$LIST" = '' ]
  then
    whiptail --msgbox "Keine Accounts vorhanden." 12 60 
    return `false`
  fi

  # Per whiptail die Liste darstellen und den
  # gew�nschten Accountnamen in der Datei choice.$$
  # speichern
  eval   "whiptail                                 \
         --menu \"Vorhandene Mailaccounts:\"       \
	 12 60 3 $LIST 2> $FILE"
}

get_nick()
{
  whiptail --inputbox "Bitte das K�rzel f�r den zu erstellenden Account eingeben.  Die Mailadresse ergibt sich aus [k�rzel]@schule.de" 12 60 2> $FILE
}

get_fullname()
{
  whiptail --inputbox 						\
  "Geben Sie nun bitte den vollen Namen des Accountinhabers an."\
  12 60 2> $FILE
}

get_forward()
{
  whiptail --inputbox \
  "Geben Sie die eMail-Adresse ein, an die eMails f�r den User $1 weitergeleitet werden sollen:" 12 60 2> $FILE
}

get_ack()
{
   whiptail --yesno "Sind Sie sicher, dass f�r $NAME die eMail-Adresse $NICK@schule.de eingerichtet werden soll?" 12 60
}

get_choice()
{
  cat $FILE
}

while `true`
do
  show_menu

  case $(get_choice) in
  Erstellen)
    get_nick || continue
    NICK=$(get_choice | sed 's/[^a-zA-Z0-9._]//g')

    get_fullname || continue
    NAME=$(get_choice | sed 's/[^a-zA-Z0-9����._ ]//g')

    get_ack || continue

    useradd -c "$NAME" -s /bin/schule -m "$NICK" 

    if [ "$?" != "0" ]
    then
      echo "oops.. Da ist wohl was schiefgelaufen. :-/"
      sleep 3
      continue
    fi

    echo "Bitte setzen Sie nun das Passwort f�r den Mailaccount: "
    passwd $NICK 

    if [ "$?" != "0" ]
    then
      echo "oops.. Da ist wohl was schiefgelaufen. :-/"
      sleep 3
      continue
    fi

    ./cyr_add $NICK
    sleep 1
    
  ;;

  Weiterleitung)
    
    show_list || continue
    NICK="$(get_choice)"

    get_forward "$NICK" || continue

    if [ "$(get_choice)" != "" ] 
    then
      echo $(get_choice) > /home/$(echo $NICK | cut -d@ -f1)/.forward
    fi

  ;;

  L�schen)

    show_list || continue
    NICK="$(get_choice | cut -d@ -f1)"
   
    whiptail --defaultno --yesno "Wollen Sie die Mailbox des Users $NICK wirklich l�schen? Dabei werden eMails und sonstige pers�nliche Dateien _unwiderruflich_ zerst�rt.\nAbfrage 1 von 3" 12 60 || continue
    whiptail --defaultno --yesno "Wollen Sie die Mailbox des Users $NICK wirklich l�schen? Dabei werden eMails und sonstige pers�nliche Dateien _unwiderruflich_ zerst�rt.\nAbfrage 2 von 3" 12 60 || continue
    whiptail --defaultno --yesno "Wollen Sie die Mailbox des Users $NICK wirklich l�schen? Dabei werden eMails und sonstige pers�nliche Dateien _unwiderruflich_ zerst�rt.\nAbfrage 3 von 3" 12 60 || continue

    deluser --remove-home $NICK
    ./cyr_del $NICK

  esac

done

exit

# Die Datei wieder l�schen
rm choice.$$

