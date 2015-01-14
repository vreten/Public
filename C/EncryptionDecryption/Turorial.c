// Encryption/Decryption Example
// 
// Matthew Beck
// 
// October 2012
// 
// My paypal account email is iamsexybeastman@hotmail.com
// 
// Send me money if you use this
// 
// Or if you just think I'm cool :D
// 
// You will surely join the ranks in the cool book!


#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>

#include <windows.h>

HANDLE wHnd;    // Handle to write to the console.

HANDLE rHnd;    // Handle to read from the console.

void setConsole();

#define SIZE 500

// These functions are defined after int main()
int thisNumberIsPrime(unsigned long input);
unsigned long generateKey();
unsigned long generateLock(unsigned long key,
                           unsigned long prime_modulus,
                           unsigned long primitive_root
                           );
unsigned long generateSharedCipher(unsigned long key,
                                   unsigned long prime_modulus,
                                   unsigned long lock
                                   );

unsigned char encryptOneChar(char in, unsigned char cypher);

void encryptFourChars(unsigned char * in, 
                                 unsigned long cypher,
                                 unsigned char * out
                                 );

unsigned char decryptOneChar(char in, unsigned char cypher);

void decryptFourChars(unsigned char * in, 
                                 unsigned long cypher,
                                 unsigned char * out
                                 );


int readInStringFromFile(FILE * file_pointer, char ** string);


// Program starts here
int main() {
    
    setConsole();
    
    // Create variables, open files
    int i, j, k;
    FILE* ifp = fopen("input_file_1.txt", "r");
    FILE* ofp = fopen("output_file_1.txt", "w");
    
    // Look up #include for long long (true crypt)
    unsigned long prime_modulus = 4294967291u; // Largest 32-bit prime
    unsigned long primitive_root = 279470273u; 
    // Found in:  
    // https://svn.mcs.anl.gov/repos/mpi/mpich2/trunk/test/mpi/coll/nonblocking3.c
    
    // Why yes, this could be stronger.
    srand(time(0));
    
    // Create variables to hold keys (private)
    unsigned long key_A, key_B;
    
    // Create variables to hold locks (public)
    unsigned long lock_A, lock_B;
    
    // Create variables to hold shared secret (private)
    unsigned long shared_cipher_A, shared_cipher_B;
    
    // Create memory to hold secret message
    char* message_before = (char*)malloc(SIZE*sizeof(char));
    system("Pause");
    // Read in a string from a file AND set the MESSAGE_SIZE
    // MESSAGE_SIZE does NOT include the string terminating character
    int MESSAGE_SIZE = readInStringFromFile(ifp, &message_before);
    system("Pause");
    // Create memory to hold encrypted message
    unsigned char* encrypted_message = (char*)malloc(MESSAGE_SIZE * sizeof(char));
    system("Pause");
    // Create memory to hold decrypted message
    char* recovered_message = (char*)malloc(MESSAGE_SIZE * sizeof(char));
    
    // Set up table
    printf("i\tkey_A\tkey_B\tlock_A\t\tlock_B\t\tshared_cipher's\n"
           "--------------------------------------------------------------------------\n");
        
    // Encrypt and decrypt the message
    for(i=0; i<MESSAGE_SIZE; i+=4){
        printf("%d\t", i);
        
        // Generates random private key
        key_A = generateKey(); // known only by A
        key_B = generateKey(); // known only by B
        printf("%X\t%X\t", key_A, key_B);
        
        // Create locks (public)
        lock_A = generateLock(key_A, prime_modulus, primitive_root);
        lock_B = generateLock(key_B, prime_modulus, primitive_root);
        printf("%X       \t%X       \t", lock_A, lock_B);
        
        // Generate shared secret
        unsigned long shared_cipher_A = generateSharedCipher(key_A, 
                                                             prime_modulus, 
                                                             lock_B
                                                             );
        unsigned long shared_cipher_B = generateSharedCipher(key_B, 
                                                             prime_modulus, 
                                                             lock_A
                                                             );
        printf("%X(%X)\n", shared_cipher_A, shared_cipher_B);
        
        
        // Because strings are stored literally as the address of the first
        // character, we increment the address by 4 each time; this is because
        // one shared cypher has exactly enough seemingly random information 
        // to encrypt exactly 4 characters
        encryptFourChars(message_before+i, shared_cipher_A, encrypted_message+i);
        decryptFourChars(encrypted_message+i, shared_cipher_A, recovered_message+i);
        
    }
    
    
    /* 
     * Print out all the resultant strings
     */
    printf("\n\n");    
    printf("message_before\n"
           "--------------\n\n");
    printf("|%s|", message_before);
    getchar();
   
    // Print out the encrypted_message as HEX values. (as opposed to a %s)
    // Be my guest at printf-ing this out with a %s (ASCII of random char)
    printf("\n\n"); 
    printf("encrypted_message\n"
           "-----------------\n\n");
    printf("\n\n\n|%s|\n\n\n", encrypted_message);
    getchar();
    for(i=0; i<MESSAGE_SIZE; i++)
         printf("%X ", encrypted_message[i]);
    getchar();
    
    printf("\n\n"); 
    printf("recovered_message\n"
           "-----------------\n\n");
    printf("|%s|", recovered_message);
    getchar();
    
    
    
    // Delete all information
    key_A = 0;               // Private
    key_B = 0;               // Private
    shared_cipher_A = 0;     // Private
    shared_cipher_B = 0;     // Private
    lock_A = 0;              // Public
    lock_B = 0;              // Public
    MESSAGE_SIZE = 0 ;       // Figure-outable
    
    // Delete message_before
    for(j = 0;j<SIZE; j++)
        message_before[j] = 0;
    free(message_before);
    
    // Delete encrypted_message
    for(j = 0;j<SIZE; j++)
        encrypted_message[j] = 0;
    free(encrypted_message);
    
    // Delete recovered_message
    for(j = 0;j<SIZE; j++)
        recovered_message[j] = 0;
    free(recovered_message);
    
    
    fclose(ifp);
    fclose(ofp);
    
} // End of program


// Function definitions:

// Again, yes, this could be stronger
unsigned long generateKey(){
    return rand();
}

// Modular Exponentiation Algorithm
unsigned long generateLock(unsigned long key,
                           unsigned long prime_modulus,
                           unsigned long primitive_root
                           ){
    int i;
    unsigned long lock = 1;
    for(i=0; i<key; i++){
        lock *= primitive_root;
        lock %= prime_modulus;
    }
    lock %= prime_modulus;
    return lock;
}

// Exact Same Modular Exponentiation Algorithm
unsigned long generateSharedCipher(unsigned long key,
                                   unsigned long prime_modulus,
                                   unsigned long lock
                                   ){
    int i;
    unsigned long cipher = 1;
    for(i=0; i<key; i++){
        cipher *= lock;
        cipher %= prime_modulus;
    }
    cipher %= prime_modulus;
    return cipher;
}

// Shift Cypher
unsigned char encryptOneChar(char in, unsigned char cypher){
    return in + cypher;
}

// Shift it back
unsigned char decryptOneChar(char in, unsigned char cypher){
    return in - cypher;
}

// Call encryptOneChar 4 times
void encryptFourChars(unsigned char * in, 
                                 unsigned long cypher,
                                 unsigned char * out
                                 ){
    int i;
    for(i=0; i<4; i++) {
        out[i] = encryptOneChar(in[i], cypher % 0x100);
        cypher /= 0x100;
    }
}

// Call decryptOneChar 4 times
void decryptFourChars(unsigned char * in, 
                                 unsigned long cypher,
                                 unsigned char * out
                                 ){
    int i;
    for(i=0; i<4; i++) {
        out[i] = decryptOneChar(in[i], cypher % 0x100);
        cypher /= 0x100;
    }
}


// Recursive Primality Test
int thisNumberIsPrime(unsigned long input){

    unsigned long factorCandidate = 2;
    
    double squareRootOfInput = (double)sqrt(input);
    
    while(factorCandidate<=squareRootOfInput){
        
        if(input % factorCandidate == 0)
            return 0;
        
        factorCandidate++;
        
        while(!thisNumberIsPrime(factorCandidate))
            factorCandidate++;
        
    }
    
    return 1;
}


// DOUBLE POINTERS!!!! AGAGHGHAHGHAHGHAGH!!!!
int readInStringFromFile(FILE * file_pointer, char ** string){
    
    int i;
    char * temp = *string;
    
    // Read in string from file
    for(i = 0;!feof(file_pointer); i++)
        fscanf(file_pointer, "%c", &temp[i]);    
    temp[i-1] = 0;    
    
    return i - 1;

}


// Copied from 
 // http://programming-technique.blogspot.com/2011/09/how-to-resize-console-window-using-c.html
void setConsole() {

    // Set up the handles for reading/writing:

    wHnd = GetStdHandle(STD_OUTPUT_HANDLE);

    rHnd = GetStdHandle(STD_INPUT_HANDLE);

    // Change the window title:

    SetConsoleTitle("Encryption/Decryption Example");

    // Create a COORD to hold the buffer size:

    COORD bufferSize = {80, SIZE};

    SetConsoleScreenBufferSize(wHnd, bufferSize);

    return;

}
