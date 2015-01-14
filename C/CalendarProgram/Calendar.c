/* Matt Beck
   2/10/12
   Calendar
    */

#include <stdio.h>
#include <string.h>
#include <Windows.h>

#define LEAP_YEAR  0
#define MAX_DAYS  365
#define DAY_START 2
#define INPUT_FILENAME "Appointments.txt"
#define LINES_PER_DAY 5
#define MAX_APPOINTMENTS 90

struct month {
       int monthNumber;
       char shortName[5];
       char longName[15];
       int NumberOfDays;
};

struct appointment {
       char month[15];
       int day;
       char message[LINES_PER_DAY*15];
};

int main(void) {
  
  int i, j, k, line, dayNumber, monthNumber;
  unsigned char monthlyDayStart, thereIsAMessage = 0, messageNumber;
  char numberOfMessages, weekdayNumber, weekdayAppointment[7];
  char tempString1[15];
  char tempString2[15];
  
  system("color 0a");
  system("mode con: cols=160 lines=2000");
  
  
  struct month myYear[12];
  for(i=0;i<12;i++){    
      myYear[i].monthNumber = i+1;
      switch (i) {
             case 0:
                  strcpy(myYear[i].shortName, "Jan");
                  strcpy(myYear[i].longName, "January");
                  myYear[i].NumberOfDays = 31;
                  break;
             case 1:
                  strcpy(myYear[i].shortName, "Feb");
                  strcpy(myYear[i].longName, "February");
                  if(LEAP_YEAR) myYear[i].NumberOfDays = 29;
                  else myYear[i].NumberOfDays = 28;
                  break;
             case 2:
                  strcpy(myYear[i].shortName, "Mar");
                  strcpy(myYear[i].longName, "March");
                  myYear[i].NumberOfDays = 31;
                  break;
             case 3:
                  strcpy(myYear[i].shortName, "Apr");
                  strcpy(myYear[i].longName, "April");
                  myYear[i].NumberOfDays = 30;
                  break;
             case 4:
                  strcpy(myYear[i].shortName, "May");
                  strcpy(myYear[i].longName, "May");
                  myYear[i].NumberOfDays = 31;
                  break;
             case 5:
                  strcpy(myYear[i].shortName, "Jun");
                  strcpy(myYear[i].longName, "June");
                  myYear[i].NumberOfDays = 30;
                  break;
             case 6:
                  strcpy(myYear[i].shortName, "Jul");
                  strcpy(myYear[i].longName, "July");
                  myYear[i].NumberOfDays = 31;
                  break;
             case 7:
                  strcpy(myYear[i].shortName, "Aug");
                  strcpy(myYear[i].longName, "August");
                  myYear[i].NumberOfDays = 31;
                  break;
             case 8:
                  strcpy(myYear[i].shortName, "Sep");
                  strcpy(myYear[i].longName, "September");
                  myYear[i].NumberOfDays = 30;
                  break;
             case 9:
                  strcpy(myYear[i].shortName, "Oct");
                  strcpy(myYear[i].longName, "October");
                  myYear[i].NumberOfDays = 31;
                  break;
             case 10:
                  strcpy(myYear[i].shortName, "Nov");
                  strcpy(myYear[i].longName, "November");
                  myYear[i].NumberOfDays = 30;
                  break;
             case 11:
                  strcpy(myYear[i].shortName, "Dec");
                  strcpy(myYear[i].longName, "December");
                  myYear[i].NumberOfDays = 31;
                  break;
             default:
                  printf("Month Number Error");
                  system("pause");
                  return 0;
                  break;
      }// Close Switch Statement
  } // CLose For Loop
  
  FILE* ifp = fopen(INPUT_FILENAME, "r");
  struct appointment myAppointments[MAX_APPOINTMENTS];
  
  SYSTEMTIME str_t;
  GetSystemTime(&str_t);
  strcpy(myAppointments[0].month, myYear[str_t.wMonth-1].shortName);
  myAppointments[0].day = str_t.wDay;
  strcpy(myAppointments[0].message, "TODAY");
  
  printf("%s %d - %s\n", strupr(myAppointments[0].month), myAppointments[0].day, myAppointments[0].message);
  
  for(i=1;!feof(ifp);i++){
      fscanf(ifp, "%s %d %[^\n]", &myAppointments[i].month, &myAppointments[i].day, &myAppointments[i].message);
      strcpy(tempString1, myAppointments[i].month);
      for(j=0;j<i;j++){
         strcpy(tempString2, myAppointments[j].month);
         if((!strcmp(strupr(tempString1), strupr(tempString2)))
            && myAppointments[j].day == myAppointments[i].day){
              strcat(myAppointments[j].message, " & ");
              strcat(myAppointments[j].message, myAppointments[i].message);
              i--;
              printf("%s %d - %s\n", strupr(myAppointments[j].month), myAppointments[j].day, myAppointments[j].message);
              break;
          }
      }
      printf("%s %d - %s\n", strupr(myAppointments[i].month), myAppointments[i].day, myAppointments[i].message);
  }
  numberOfMessages = i;
  printf("\t   %c", 201);

  for(j=0;j<7;j++){
      for(k=0;k<15;k++)
          printf("%c", 205);  
      if(j==6)
          printf("%c", 187);
      else
          printf("%c", 209);      
  }
  
  printf("\n\t   %c\tSUN\t   %c\tMON\t   %c\tTUES\t   %c\tWED\t   %c\tTHUR\t   %c\tFRI\t\t   %c\tSAT\t   %c\n\t   %c", 186, 179, 179, 179, 179, 179, 179, 186, 204);  
  for(j=0;j<7;j++){
      for(k=0;k<15;k++)
          printf("%c", 205);  
      if(j==6)
          printf("%c", 185);
      else {
          if(j+1 == DAY_START)
              printf("%c", 201); 
          else
              printf("%c", 216); 
      }     
  }
  printf("\n  January  ");
  
  
  // Offset for DAY_START
  for(i=0;i<DAY_START;i++){
      if(i==0)
          printf("%c", 186);
      else 
          printf("%c", 179);
      for(j=0; j<15; j++)
          printf(" ");
  }
  
  
  
  monthlyDayStart = DAY_START;
  dayNumber = 1;
  monthNumber = 1;
  for(i=0;i<7;i++) weekdayAppointment[i] = -1;
  for(i=monthlyDayStart; i<(MAX_DAYS+monthlyDayStart); i++, dayNumber++){
      
      weekdayNumber = i%7;
      
      strcpy(tempString1, myYear[monthNumber-1].shortName);
      strcpy(tempString2, myYear[monthNumber-1].longName);
      for(j=0, weekdayAppointment[weekdayNumber] = -1;j<numberOfMessages;j++){
          if((!strcmp(strupr(tempString1), strupr(myAppointments[j].month)) 
           || !strcmp(strupr(tempString2), strupr(myAppointments[j].month))) 
           && myAppointments[j].day == dayNumber){
              weekdayAppointment[weekdayNumber] = j;
              break;
          }
      }
      
      if((dayNumber==1) || ((i)%7==0))
          printf("%c", 186);
      else 
          printf("%c", 179);
      
      printf("%2d ", dayNumber);
      for(j=0;j<12;j++){
          if(weekdayAppointment[weekdayNumber] != -1){
              if(myAppointments[weekdayAppointment[weekdayNumber]].message[j] != '\0')
                  printf("%c", myAppointments[weekdayAppointment[weekdayNumber]].message[j]);
              else {
                  printf(" ");
                  weekdayAppointment[weekdayNumber] = -1;
              }
          }
          else printf(" ");
      }
      
      // For each week
      if((i+1)%7==0){
          
          printf("%c\n", 186);// ||
          
          for(line=0;line<LINES_PER_DAY;line++){
              
              printf("\t   %c", 186); // ||
              for(j=0;j<7;j++){
                  for(k=0;k<15;k++){
                      if(weekdayAppointment[j] != -1){
                          //printf("%d:%d, %d - %d", dayNumber, weekdayNumber, j, weekdayAppointment[j]);
                          //system("pause");
                          if(myAppointments[weekdayAppointment[j]].message[12 + 15*line + k] != '\0')
                              printf("%c", myAppointments[weekdayAppointment[j]].message[12 + 15*line + k]);
                          else {
                              printf(" ");
                              weekdayAppointment[j] = -1;
                          }
                      }
                      else printf(" ");
                  }
                  if(j==6 || j == 6 - dayNumber)
                      printf("%c", 186); // ||
                  else
                      printf("%c", 179); // |
              }
              printf("\n");
          }
          
          if(dayNumber < 7 || (myYear[monthNumber-1].NumberOfDays == dayNumber))
              printf("\t   %c", 204); // |¦=
          else 
              printf("\t   %c", 199);// ||-
          
          for(j=0;j<7;j++){
              for(k=0;k<15;k++){
                  if((j >= myYear[monthNumber-1].NumberOfDays-dayNumber) || j < 7 - dayNumber )
                      printf("%c", 205); // =
                  else
                      printf("%c", 196); // -
              }
              if(j==6){
                  if(myYear[monthNumber-1].NumberOfDays-dayNumber<7)
                      printf("%c", 185); // =¦|
                  else
                      printf("%c", 182); // -||
              }
              else if((j >= myYear[monthNumber-1].NumberOfDays-dayNumber) || j < 6 - dayNumber )
                  printf("%c", 216); // !=
              else if(j == 6 - dayNumber)
                  printf("%c", 188); // _>>
              else if((j+1 == myYear[monthNumber-1].NumberOfDays-dayNumber))
                  printf("%c", 201);// <<
              else
                  printf("%c", 197);// + 
          }
          printf("\n");
          
          // Print month name(s)
          if(myYear[monthNumber-1].NumberOfDays==dayNumber)
              printf("%9s  ", myYear[monthNumber].longName);
          else if(dayNumber > myYear[monthNumber-1].NumberOfDays-7){
              strcpy(tempString1, myYear[monthNumber-1].shortName);
              strcat(tempString1, "/");
              strcat(tempString1, myYear[monthNumber].shortName);
              printf("%9s  ", tempString1);
              
          }
          else printf("%9s  ", myYear[monthNumber-1].longName);
          
      }// Close for each week statement
      
      if(myYear[monthNumber-1].NumberOfDays==dayNumber){
          dayNumber = 0;
          monthNumber++;
          monthlyDayStart = i%7;
      }   
  }  
  system("pause");
  return 0;
}
