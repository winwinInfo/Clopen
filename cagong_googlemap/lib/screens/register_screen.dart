/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/authProvider.dart' as loginProvider;
import 'package:provider/provider.dart';
import 'login.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _universityController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isEmailVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) => value?.isEmpty ?? true ? '이름을 입력하세요' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: '성별'),
                items: ['남성', '여성'].map((String gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                validator: (value) => value == null ? '성별을 선택하세요' : null,
              ),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '생년월일'),
                  child: Text(
                    _selectedDate == null
                        ? '생년월일을 선택하세요'
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  ),
                ),
              ),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '별명'),
                validator: (value) => value?.isEmpty ?? true ? '별명을 입력하세요' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return '올바른 이메일을 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: '대학교 (선택사항)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isEmailVerified ? _signUp : _sendVerificationEmail,
                child: Text(_isEmailVerified ? '회원가입' : '이메일 인증 보내기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
        UserCredential userCredential = await authProvider.createUser(
          email: _emailController.text,
          password: _passwordController.text,
        );
        await authProvider.sendEmailVerification(userCredential.user!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 이메일을 보냈습니다. 이메일을 확인해주세요.')),
        );
        setState(() {
          _isEmailVerified = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 인증 오류: $e')),
        );
      }
    }
  }

 Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
        bool isVerified = await authProvider.isEmailVerified(
          _emailController.text,
          _passwordController.text,
        );
        
        if (isVerified) {
          await authProvider.saveUserData(
            uid: authProvider.user!.uid,
            name: _nameController.text,
            gender: _selectedGender!,
            birthDate: _selectedDate!,
            nickname: _nicknameController.text,
            email: _emailController.text,
            university: _universityController.text,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 성공!')),
          );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이메일 인증이 완료되지 않았습니다.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 오류: $e')),
        );
      }
    }
  }
}*/
