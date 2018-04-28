#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/..";
use Test::More tests => 13;

our $module;
BEGIN {
    $module = 'mocked_dbms';
    use_ok($module);
}

# new ok
my $mock = new_ok($module);

subtest 'register test data' => sub {
    my $proc = 'abc123';
    my $data = [
         IN('123456789'),
        OUT('Y'),
        CSR([1,2,3]),
        CLB('clob text'),
    ];
    $mock->register_testdata(PROC => $proc, DATA => $data);

    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789',
                                   \$out,
                                   '__CURSOR__',\$cur,
                                   '__CLOB__',  \$clb,
                                 ]);

    is($success,1, "execute_procedure");

    is($out,'Y', "Get OUT");
    is($clb,'clob text', 'Get CLOB');

    is(ref($cur), 'dataCSR', 'CURSOR Object');
    my ($v1,$v2,$v3) = $cur->fetchrow_array;
    is($v1,1,"get v1 from CURSOR");
    is($v2,2,"get v2 from CURSOR");
    is($v3,3,"get v3 from CURSOR");
    $success = $cur->finish();
    is($success,1,"close dataCSR");
    ok(scalar($cur->fetchrow_array()) == 0, 'No data in the cursor');

    done_testing();

    $mock->clean_testdata;
};

subtest 'clean test data' => sub {
    my $proc = 'abc123';
    my $data = [IN('123456789'),OUT('Y')];
    $mock->register_testdata(PROC => $proc, DATA => $data);
    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789', \$out ]);
    is($success, 1, "registered $proc");
    
    $mock->clean_testdata($proc);

    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789', \$out ]);
    is($success, 0, "cleared $proc");

    my @more_proc = qw( proc1 proc2 proc3 );
    for my $proc (@more_proc) {
        my $data = [IN('123456789'),OUT('Y')];
        $mock->register_testdata(PROC => $proc, DATA => $data);
    }
    for my $proc (@more_proc) {
        $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789', \$out ]);
        is($success, 1, "registered $proc in group");
    }
    #$mock->show_testdata;
    $mock->clean_testdata();
    for my $proc (@more_proc) {
        $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789', \$out ]);
        is($success, 0, "cleaned $proc in group");
    }

    done_testing();
};

subtest 'iteration cursor-fetching' => sub {
    my $proc = 'abc123';
    my $data = [
         IN('987654321'),
        OUT('N'),
        CSR([4,5],[6,7],[8,9]),
    ];
    $mock->register_testdata(PROC => $proc, DATA => $data);

    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '987654321',
                                   \$out,
                                   '__CURSOR__',\$cur,
                                 ]);
    is($success,1, "execute_procedure");
    
    my ($v1,$v2);
    ($v1,$v2) = $cur->fetchrow_array;
    is($v1,4,"fetch 1 time - v1");
    is($v2,5,"fetch 1 time - v2");
    ($v1,$v2) = $cur->fetchrow_array;
    is($v1,6,"fetch 2 time - v1");
    is($v2,7,"fetch 2 time - v2");
    ($v1,$v2) = $cur->fetchrow_array;
    is($v1,8,"fetch 3 time - v1");
    is($v2,9,"fetch 3 time - v2");
    $cur->finish();

    done_testing();

    $mock->clean_testdata;
};

subtest 'procedure without IN' => sub {
    my $proc = 'abc123';
    my $data = [
        OUT('Y'),
        CSR([1,2,3]),
    ];
    # without input parameter
    $mock->register_testdata(PROC => $proc, DATA => $data);

    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ 
                                   \$out,
                                   '__CURSOR__',\$cur,
                                 ]);
    is($success,1, "execute_procedure"); 
    my ($v1,$v2,$v3) = $cur->fetchrow_array;
    is($v1,1,"fetch for v1");
    is($v2,2,"fetch for v2");
    is($v3,3,"fetch for v3");
    
    done_testing();

    $mock->clean_testdata;
};

subtest 'register_spec for procedure' => sub {
    my $proc = 'abc123';
    my $in1  = IN();
    my $out1 = OUT();
    my $csr1 = CSR();
    my $clb1 = CLB();
    
    $mock->register_procedure(PROC => $proc, SPEC => [$in1,$out1,$csr1,$clb1]);
    $in1->val('123456789');
    $out1->val('Y');
    $csr1->val([1,2,3]);
    $clb1->val('clob text');
    $mock->inject();

    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789',
                                   \$out,
                                   '__CURSOR__',\$cur,
                                   '__CLOB__',  \$clb,
                                 ]);

    is($success,1, "execute_procedure");

    is($out,'Y', "Get OUT");
    is($clb,'clob text', 'Get CLOB');

    my ($v1,$v2,$v3) = $cur->fetchrow_array;
    is($v1,1,"get v1 from CURSOR");
    is($v2,2,"get v2 from CURSOR");
    is($v3,3,"get v3 from CURSOR");
    $success = $cur->finish();
    is($success,1,"close dataCSR");

    done_testing();
  
    $mock->clean_testdata;
};

subtest 'inject new test data for IN' => sub {
    my $proc = 'abc123';
    my $in1  = IN('123456789');
    my $out1 = OUT('Y');
    
    $mock->register_procedure(PROC => $proc, SPEC => [$in1,$out1])
         ->inject();

    is($in1->val('987654321'),'123456789','Update IN from 123456789 to 987654321');
    $mock->inject();
    #$mock->show_testdata;

    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789',
                                   \$out,
                                 ]);

    is($success,1, "execute_procedure - 123456789");
    is($out,'Y', "Get OUT - Y");

    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '987654321',
                                   \$out,
                                 ]);
    is($success,1, "execute_procedure - 987654321");
    is($out,'Y', "Get OUT - Y");

    done_testing();
};

subtest 'inject new test data for OUT' => sub {
    my $proc = 'abc123';
    my $in1  = IN('123456789');
    my $out1 = OUT('Y');
    
    $mock->register_procedure(PROC => $proc, SPEC => [$in1,$out1])
         ->inject();
    #$mock->show_testdata;

    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789',
                                   \$out,
                                 ]);

    is($success,1, "execute_procedure 1st - 123456789");
    is($out,'Y', "Get OUT - Y");

    is($out1->val('N'),'Y','Update OUT from Y to N');
    $mock->inject();
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789',
                                   \$out,
                                 ]);

    is($success,1, "execute_procedure 2nd - 123456789");
    is($out,'N', "Get OUT - N");
    
    done_testing();

    $mock->clean_testdata;
};

subtest 'inject new test data for CSR' => sub {
    my $proc = 'abc123';
    my $in1  = IN('123456789');
    my $csr1 = CSR([1,2,3]);
    
    $mock->register_procedure(PROC => $proc, SPEC => [$in1,$csr1])
         ->inject();
    #$mock->show_testdata;

    my ($out,$cur,$clb);
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789',
                                   '__CURSOR__',\$cur,
                                 ]);

    is($success,1, "execute_procedure 1st - 123456789");
    my ($v1,$v2,$v3) = $cur->fetchrow_array;
    is($v1,1,"get v1 from CURSOR");
    is($v2,2,"get v2 from CURSOR");
    is($v3,3,"get v3 from CURSOR");
    $success = $cur->finish();
    is($success,1,"close dataCSR");

    my $old = $csr1->val([4,5]);
    is_deeply($old,[[1,2,3]],'Update CSR from [1,2,3] to [4,5]');
    $mock->inject();
    $success = $mock->execute_procedure(
                         PROC => $proc,
                         PARAM=> [ '123456789',
                                   '__CURSOR__',\$cur,
                                 ]);

    is($success,1, "execute_procedure 2nd - 123456789");
    my ($nv1,$nv2) = $cur->fetchrow_array;
    is($nv1,4,"get v1 from CURSOR");
    is($nv2,5,"get v2 from CURSOR");
    $success = $cur->finish();
    is($success,1,"close dataCSR");

    done_testing();

    $mock->clean_testdata;
};

subtest 'case-insenstive procedure' => sub {
    my $lc_proc = 'abc123';
    my $uc_proc = 'ABC123';
    my $data = [ IN('99'), OUT('x') ];
    $mock->register_testdata(PROC => $lc_proc, DATA => $data);

    my $out;
    my $success;
    $success = $mock->execute_procedure(
                         PROC => $uc_proc,
                         PARAM=> [ '99', \$out ]);
    is($success, 1, "registered_testdata with lowercase, execute_procedure with uppercase");
    is($out, 'x', "get the out");
    
    my $spec_in = IN('99');
    my $spec_out= OUT('y');
    $mock->register_procedure(PROC=>$uc_proc, SPEC => [$spec_in,$spec_out])->inject();
    $success = $mock->execute_procedure(
                         PROC => $lc_proc,
                         PARAM=> [ '99', \$out ]);
    is($success, 1, "registered_procedure with uppercase, execute_procedure with lowercase");
    is($out, 'y', "get the out");
 
    done_testing();

    $mock->clean_testdata;
};

subtest 'exception types' => sub {
    my $proc = 'xyz123';
    my $spec = [ bless({},'unknow_type'),
                 OUT()];
    my $data = [ bless({},'unknow_type'),
                 OUT('x')];

    eval {
       $mock->register_procedure(PROC=>$proc, SPEC => $spec);
    };
    like($@, qr{TYPE\[unknow_type\] is not supported}, 'SUB[register_procedure] error data type');

    eval {
       $mock->register_testdata( PROC=>$proc, DATA => $data);
    };
    like($@, qr{TYPE\[unknow_type\] is not supported}, 'SUB[register_testdata ] error data type');
    
    eval {
       $mock->inject('xyz123');
    };
    like($@, qr{PROC\[xyz123\] has not been registered!}, 'SUB[inject] procedure is not registered');
    
    eval {
       my $csr = CSR('not_cursor');
    };
    like($@, qr{Data\[not_cursor\] is not a ARRAY}, 'SUB[CSR] error record type for cursor');

    done_testing();

    $mock->clean_testdata;
};

subtest 'AUTOLOAD from DBI' => sub {
    plan tests => 3;
    my $status;
    eval {
        $status = $mock->commit;
    };
    is($@, '',
        "commit executed");
    ok($status,
        "commit successfully");
    eval {
        $status = $mock->sth_not_in_dbh; 
    };
    like($@, qr{DBI can't do METHOD\[sth_not_in_dbh\]},
        "method not found db handler");
};
