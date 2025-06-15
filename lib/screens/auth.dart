import 'dart:io';
import 'package:chatapp/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _isAuthentication = false;

  void _submit() async{
    final isValid = _form.currentState!.validate();

       if(!isValid || !_isLogin && _selectedImage == null) {
         //...
         return;
       }

      _form.currentState!.save();
    try {
      setState(() {
        _isAuthentication = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${userCredentials.user!.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          final imageUrl = await storageRef.getDownloadURL();
          print(imageUrl);

          await FirebaseFirestore.instance
              .collection('user')
              .doc(userCredentials.user!.uid)
              .set({
                 'username' : 'to be done...',
                 'email' : _enteredEmail,
                 'image_url' : imageUrl,
              });
        ;
         }
        } on FirebaseAuthException catch (error) {
          if(error.code == 'email-already-in-use') {
            //...
          }
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(error.message ?? 'Authentication failed')
          ),
          );
          setState(() {
            _isAuthentication = false;
          });
        }
      }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat1.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child : SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.all(15),
                    child: Form(
                      key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            if(!_isLogin) UserImagePicker(onPickedImage: (pickedImage) {
                              _selectedImage = pickedImage;
                            },),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: "Email Address",
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                  if( value == null || value.trim().isEmpty || !value.contains('@')) {
                                    return 'Please enter a valid email address.';
                                  }
                                  return null;
                              },
                                onSaved: (value) {
                                  _enteredEmail = value!;
                                }
                            ),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: "Password",
                              ),
                              obscureText: true,
                              validator: (value) {
                                if( value == null || value.trim().length < 6) {
                                  return 'Please enter atleast 6 character password.';
                                }
                                return null;
                              },
                                onSaved: (value) {
                                  _enteredPassword = value!;
                                }
                            ),
                            SizedBox(height: 12,),
                            if(_isAuthentication) CircularProgressIndicator(),
                            if(!_isAuthentication)
                            ElevatedButton(
                              onPressed:  _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                                child: Text(_isLogin ? "LogIn" : "SingUp"),
                            ),
                            TextButton(
                                onPressed: () {
                              setState(() {
                                 _isLogin = !_isLogin;
                            });},
                                child: Text(_isLogin ? "Create an account" : "I have already an account")
                            ),
                          ],
                        ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
