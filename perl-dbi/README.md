# perl-dbi
the way that perl communicates with database easily

## Oracle PL/SQL
the Perl encapsulation for executing PL/SQL procedure in database

### API Usage
```pl

my $dbh = dbms->new(
    db => 'your-db-name',
    dbuser => 'user-name',
    dbpasswd => 'password',
    log_ref  => 'log-handler',
) or die "db handler init error";

my ($in, $out, $csr);
$in = '123';
$dbh->execute_procedure(
    PROC  => 'prodecure-name',
    PARAM => [ $in,
              \$out,
              '__CURSOR__', \$csr,
             ],
) or die 'execute procedure error';

# user the output: $out
# fetch data from CURSOR: $csr
$csr->fetchrow_array();

```

## UT test API 
Mock the data to support dbms.pl for execution of PL/SQL procedure during unit test

### API usage
```pl
# create this mocked dbh
# inject $mocked_dbh into your application to replce $dbh
my $mocked_dbh = mocked_dbm->new();

# test data preparation
# with register test data directly
# mostly for one-time-use API
$mocked_dbh->register_testdata(
    PROC => 'your-prodecure-to-be-executed',
    DATA => [IN('123'),    # query input
             OUT('321'),   # output
             CSR([1,2,3]), # cusor output
            ],
);



# with register producure then inject with test data
my @specs = 
my (
  $in = IN(),
  $out = OUT(),
  $csr = CSR(),
);
$mocked_dbh->register_procedure(
    PROC => 'your-prodecure-to-be-executed',
    SPEC => [@specs],
);

# setup and inject data
$in->val('123');
$out->val('321');
$csr->val([1,2,3], [3,2,1]);
$mocked_dbh->inject();

# implement your test code
...

# clean all test data
$mocked_dbh->clean_testdata();
# or clean for the one prodecure 
$mocked_dbh->clean_testdata('your-prodecure-to-be-executed');

# now you can setup data and implement another test
...

# check your test data
$mocked_dbh->show_testdata();

```
Please take more details by looking into unit test script
https://github.com/jzhangkun/perl-dbi/blob/master/PLSQL/t/mocked_dbms.t
