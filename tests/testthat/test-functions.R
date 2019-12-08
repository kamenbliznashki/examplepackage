expect_that(make_filename(2015), equals('accident_2015.csv.bz2'))

test_that('load internal raw data', {
  filepath = system.file('extdata', 'accident_2013.csv.bz2', package='examplepackage')
  df = fars_read(filename=basename(filepath), datadir=dirname(filepath))
  expect_that(df, is_a('data.frame'))
  expect_that(dim(df), equals(c(30202,50)))
})

expect_error(fars_read(make_filename(2013), datadir='.'),
             paste0('file ', "'./", make_filename(2013), "'", ' does not exist'))

