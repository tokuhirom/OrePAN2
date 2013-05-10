requires 'perl', '5.008001';

requires 'Archive::Extract', 0.68;
requires 'Module::Metadata';
requires 'File::Temp';
requires 'File::pushd';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

